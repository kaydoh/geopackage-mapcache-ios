//
//  GPKGSMapViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/13/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSMapViewController.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSDatabases.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSTileTable.h"
#import "GPKGOverlayFactory.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGProjectionFactory.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSFeatureOverlayTable.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGFeatureTiles.h"
#import "GPKGFeatureIndexer.h"
#import "GPKGFeatureOverlay.h"
#import "GPKGSUtils.h"
#import "GPKGSDownloadTilesViewController.h"
#import "GPKGSCreateTilesData.h"
#import "GPKGSSelectFeatureTableViewController.h"

NSString * const GPKGS_MAP_SEG_DOWNLOAD_TILES = @"downloadTiles";
NSString * const GPKGS_MAP_SEG_SELECT_FEATURE_TABLE = @"selectFeatureTable";
NSString * const GPKGS_MAP_SEG_FEATURE_TILES_REQUEST = @"featureTiles";
NSString * const GPKGS_MAP_SEG_EDIT_FEATURES_REQUEST = @"editFeatures";

@interface GPKGSMapViewController ()

@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSMutableDictionary * geoPackages;
@property (nonatomic, strong) GPKGBoundingBox * featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@property (nonatomic) BOOL featureOverlayTiles;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, strong) NSUserDefaults * settings;
@property (atomic) int updateCountId;
@property (nonatomic) BOOL boundingBoxMode;
@property (nonatomic) BOOL editFeaturesMode;
@property (nonatomic) CLLocationCoordinate2D boundingBoxStartCorner;
@property (nonatomic) CLLocationCoordinate2D boundingBoxEndCorner;
@property (nonatomic, strong) MKPolygon * boundingBox;
@property (nonatomic) BOOL drawing;
@property (nonatomic, strong) NSString * editFeaturesDatabase;
@property (nonatomic, strong) NSString * editFeaturesTable;
@property (nonatomic, strong) UIColor * boundingBoxColor;
@property (nonatomic) double boundingBoxLineWidth;
@property (nonatomic, strong) UIColor * boundingBoxFillColor;
@property (nonatomic) BOOL internalSeg;
@property (nonatomic, strong) NSString * segRequest;

@end

@implementation GPKGSMapViewController

#define TAG_MAP_TYPE 1
#define TAG_MAX_FEATURES 2

- (void)viewDidLoad {
    [super viewDidLoad];
    self.updateCountId = 0;
    self.settings = [NSUserDefaults standardUserDefaults];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    self.geoPackages = [[NSMutableDictionary alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager requestWhenInUseAuthorization];
    [self resetBoundingBox];
    [self resetEditFeatures];
    [self.mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(longPressGesture:)]];
    self.boundingBoxStartCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBoxEndCorner = kCLLocationCoordinate2DInvalid;
    
    self.boundingBoxColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_COLOR]];
    self.boundingBoxLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL]){
        self.boundingBoxFillColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL_COLOR]];
    }
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if(self.internalSeg){
        self.internalSeg = false;
    }else{
        if(self.active.modified){
            [self.active setModified:false];
            [self resetBoundingBox];
            [self resetEditFeatures];
            [self updateInBackgroundWithZoom:true];
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        if(self.drawing || (self.boundingBox != nil && self.boundingBox == overlay)){
            MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
            polygonRenderer.strokeColor = self.boundingBoxColor;
            polygonRenderer.lineWidth = self.boundingBoxLineWidth;
            if(self.boundingBoxFillColor != nil){
                polygonRenderer.fillColor = self.boundingBoxFillColor;
            }
            rendered = polygonRenderer;
        }else{
            MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
            polygonRenderer.strokeColor = [UIColor blackColor];
            polygonRenderer.lineWidth = 1.0;
            rendered = polygonRenderer;
        }
    }else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineRenderer.strokeColor = [UIColor blackColor];
        polylineRenderer.lineWidth = 1.0;
        rendered = polylineRenderer;
    }else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        rendered = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return rendered;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
        case TAG_MAP_TYPE:
            [self handleMapTypeWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_MAX_FEATURES:
            [self handleMaxFeaturesWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
}

-(void) longPressGesture:(UILongPressGestureRecognizer *) longPressGestureRecognizer{
    
    CGPoint cgPoint = [longPressGestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];
    
    if(self.boundingBoxMode){
    
        if(longPressGestureRecognizer.state == UIGestureRecognizerStateBegan){
            
            // Check to see if editing any of the bounding box corners
            if (self.boundingBox != nil && CLLocationCoordinate2DIsValid(self.boundingBoxEndCorner)) {
                
                double allowableScreenPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_LONG_CLICK_SCREEN_PERCENTAGE] intValue] / 100.0;
                if([self isWithinDistanceWithPoint:cgPoint andLocation:self.boundingBoxEndCorner andAllowableScreenPercentage:allowableScreenPercentage]){
                    [self setDrawing:true];
                }else if([self isWithinDistanceWithPoint:cgPoint andLocation:self.boundingBoxStartCorner andAllowableScreenPercentage:allowableScreenPercentage]){
                    CLLocationCoordinate2D temp = self.boundingBoxStartCorner;
                    self.boundingBoxStartCorner = self.boundingBoxEndCorner;
                    self.boundingBoxEndCorner = temp;
                    [self setDrawing:true];
                }else{
                    CLLocationCoordinate2D corner1 = CLLocationCoordinate2DMake(self.boundingBoxStartCorner.latitude, self.boundingBoxEndCorner.longitude);
                    CLLocationCoordinate2D corner2 = CLLocationCoordinate2DMake(self.boundingBoxEndCorner.latitude, self.boundingBoxStartCorner.longitude);
                    if([self isWithinDistanceWithPoint:cgPoint andLocation:corner1 andAllowableScreenPercentage:allowableScreenPercentage]){
                        self.boundingBoxStartCorner = corner2;
                        self.boundingBoxEndCorner = corner1;
                        [self setDrawing:true];
                    }else if([self isWithinDistanceWithPoint:cgPoint andLocation:corner2 andAllowableScreenPercentage:allowableScreenPercentage]){
                        self.boundingBoxStartCorner = corner1;
                        self.boundingBoxEndCorner = corner2;
                        [self setDrawing:true];
                    }
                }
            }
            
            // Start drawing a new polygon
            if(!self.drawing){
                if(self.boundingBox != nil){
                    [self.mapView removeOverlay:self.boundingBox];
                }
                self.boundingBoxStartCorner = point;
                self.boundingBoxEndCorner = point;
                CLLocationCoordinate2D * points = [self getPolygonPointsWithPoint1:self.boundingBoxStartCorner andPoint2:self.boundingBoxEndCorner];
                self.boundingBox = [MKPolygon polygonWithCoordinates:points count:4];
                [self.mapView addOverlay:self.boundingBox];
                [self setDrawing:true];
                [self.boundingBoxClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_CLEAR_ACTIVE_IMAGE] forState:UIControlStateNormal];
            }
            
        }else{
            switch(longPressGestureRecognizer.state){
                case UIGestureRecognizerStateChanged:
                case UIGestureRecognizerStateEnded:
                    if(self.boundingBoxMode){
                        if(self.drawing && self.boundingBox != nil){
                            self.boundingBoxEndCorner = point;
                            CLLocationCoordinate2D * points = [self getPolygonPointsWithPoint1:self.boundingBoxStartCorner andPoint2:self.boundingBoxEndCorner];
                            MKPolygon * newBoundingBox = [MKPolygon polygonWithCoordinates:points count:4];
                            [self.mapView removeOverlay:self.boundingBox];
                            [self.mapView addOverlay:newBoundingBox];
                            self.boundingBox = newBoundingBox;
                        }
                        if(longPressGestureRecognizer.state == UIGestureRecognizerStateEnded){
                            [self setDrawing:false];
                        }
                    }
                    break;
                default:
                    break;
            }
        }
    }
}

-(BOOL) isWithinDistanceWithPoint: (CGPoint) point andLocation: (CLLocationCoordinate2D) location andAllowableScreenPercentage: (double) allowableScreenPercentage{
    
    CGPoint locationPoint = [self.mapView convertCoordinate:location toPointToView:self.mapView];
    double distance = sqrt(pow(point.x - locationPoint.x, 2) + pow(point.y - locationPoint.y, 2));
    
    BOOL withinDistance = distance / MIN(self.mapView.frame.size.width, self.mapView.frame.size.height) <= allowableScreenPercentage;
    return withinDistance;
}

-(CLLocationCoordinate2D *) getPolygonPointsWithPoint1: (CLLocationCoordinate2D) point1 andPoint2: (CLLocationCoordinate2D) point2{
    CLLocationCoordinate2D *coordinates = calloc(4, sizeof(CLLocationCoordinate2D));
    coordinates[0] = CLLocationCoordinate2DMake(point1.latitude, point1.longitude);
    coordinates[1] = CLLocationCoordinate2DMake(point1.latitude, point2.longitude);
    coordinates[2] = CLLocationCoordinate2DMake(point2.latitude, point2.longitude);
    coordinates[3] = CLLocationCoordinate2DMake(point2.latitude, point1.longitude);
    return coordinates;
}

- (IBAction)zoomToActiveButton:(id)sender {
    [self zoomToActive];
}

- (IBAction)featuresButton:(id)sender {
    self.segRequest = GPKGS_MAP_SEG_EDIT_FEATURES_REQUEST;
    [self performSegueWithIdentifier:GPKGS_MAP_SEG_SELECT_FEATURE_TABLE sender:self];
}

- (IBAction)boundingBoxButton:(id)sender {
    if(!self.boundingBoxMode){
        
        if(self.editFeaturesMode){
            [self resetEditFeatures];
            [self updateInBackgroundWithZoom:false];
        }
        
        self.boundingBoxMode = true;
        [self.downloadTilesButton setHidden:false];
        [self.featureTilesButton setHidden:false];
        [self.boundingBoxClearButton setHidden:false];
        [self.boundingBoxButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_ACTIVE_IMAGE] forState:UIControlStateNormal];
    }else{
        [self resetBoundingBox];
    }
}

- (IBAction)downloadTilesButton:(id)sender {
    [self performSegueWithIdentifier:GPKGS_MAP_SEG_DOWNLOAD_TILES sender:self];
}

- (IBAction)featureTilesButton:(id)sender {
    self.segRequest = GPKGS_MAP_SEG_FEATURE_TILES_REQUEST;
    [self performSegueWithIdentifier:GPKGS_MAP_SEG_SELECT_FEATURE_TABLE sender:self];
}

- (IBAction)boundingBoxClearButton:(id)sender {
    [self clearBoundingBox];
}

-(void) resetBoundingBox{
    self.boundingBoxMode = false;
    [self.downloadTilesButton setHidden:true];
    [self.featureTilesButton setHidden:true];
    [self.boundingBoxClearButton setHidden:true];
    [self.boundingBoxButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_IMAGE] forState:UIControlStateNormal];
    [self clearBoundingBox];
}

-(void) resetEditFeatures{
    self.editFeaturesMode = false;
    //TODO reset edit features
    [self clearEditFeatures];
}

-(void) clearBoundingBox{
    [self.boundingBoxClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_CLEAR_IMAGE] forState:UIControlStateNormal];
    if(self.boundingBox != nil){
        [self.mapView removeOverlay:self.boundingBox];
    }
    self.boundingBoxStartCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBoxEndCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBox = nil;
    [self setDrawing:false];
}

-(void) clearEditFeatures{
    //TODO clear edit features
}

- (IBAction)userLocation:(id)sender {
    if([CLLocationManager locationServicesEnabled]){
        [self.locationManager startUpdatingLocation];
    }
}

- (IBAction)maxFeaturesButton:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES]
                           message:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_MESSAGE]
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField* textField = [alert textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    [textField setText:[NSString stringWithFormat:@"%d", [self getMaxFeatures]]];
    alert.tag = TAG_MAX_FEATURES;
    [alert show];
}

- (void) handleMaxFeaturesWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString * maxFeatures = [[alertView textFieldAtIndex:0] text];
        if(maxFeatures != nil && [maxFeatures length] > 0){
            @try {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *maxFeaturesNumber = [formatter numberFromString:maxFeatures];
                [self.settings setInteger:[maxFeaturesNumber integerValue] forKey:GPKGS_PROP_MAP_MAX_FEATURES];
                [self.settings synchronize];
                [self updateInBackgroundWithZoom:false];
            }
            @catch (NSException *e) {
                NSLog(@"Invalid max features value: %@, Error: %@", maxFeatures, [e description]);
            }
        }
    }
}

- (IBAction)mapType:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE]
                           message:nil
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD],
                           [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE],
                           [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_HYBRID],
                           nil];
    alert.tag = TAG_MAP_TYPE;
    [alert show];
}

- (void) handleMapTypeWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        MKMapType mapType;
        switch(buttonIndex){
            case 1:
                mapType = MKMapTypeStandard;
                break;
            case 2:
                mapType = MKMapTypeSatellite;
                break;
            case 3:
                mapType = MKMapTypeHybrid;
                break;
            default:
                mapType = MKMapTypeStandard;
        }
        [self.mapView setMapType:mapType];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLLocation * userLocation = self.mapView.userLocation.location;
    if(userLocation != nil){
        
        MKCoordinateRegion region;
        region.center = self.mapView.userLocation.coordinate;
        region.span = MKCoordinateSpanMake(0.02, 0.02);
        
        region = [self.mapView regionThatFits:region];
        [self.mapView setRegion:region animated:YES];
        
        //[self.mapView setCenterCoordinate:userLocation.coordinate animated:YES];
        
        [self.locationManager stopUpdatingLocation];
    }
}

-(int) updateInBackgroundWithZoom: (BOOL) zoom{
    
    int updateId = ++self.updateCountId;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    for(GPKGGeoPackage * geoPackage in [self.geoPackages allValues]){
        @try {
            [geoPackage close];
        }
        @catch (NSException *exception) {
        }
    }
    [self.geoPackages removeAllObjects];
    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;
    self.featureOverlayTiles = false;
    int maxFeatures = [self getMaxFeatures];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        [self updateWithId: updateId andZoom:zoom andMaxFeatures:maxFeatures];
    });
}

-(BOOL) updateCanceled: (int) updateId{
    BOOL canceled = updateId < self.updateCountId;
    return canceled;
}

-(int) updateWithId: (int) updateId andZoom: (BOOL) zoom andMaxFeatures: (int) maxFeatures{
    
    int count = 0;
    
    if(self.active != nil){
        
        NSArray * activeDatabases = [[NSArray alloc] initWithArray:[self.active getDatabases]];
        for(GPKGSDatabase * database in activeDatabases){
            
            GPKGGeoPackage * geoPackage = [self.manager open:database.name];
            
            if(geoPackage != nil){
                [self.geoPackages setObject:geoPackage forKey:database.name];
                
                for(GPKGSTileTable * tiles in [database getTiles]){
                    @try {
                        [self displayTiles:tiles];
                    }
                    @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    }
                    if([self updateCanceled:updateId]){
                        break;
                    }
                }
             
                for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                    if(featureOverlay.active){
                        @try {
                            [self displayFeatureTiles:featureOverlay];
                        }
                        @catch (NSException *e) {
                            NSLog(@"%@", [e description]);
                        }
                    }
                    if([self updateCanceled:updateId]){
                        break;
                    }
                }
            } else{
                [self.active removeDatabase:database.name andPreserveOverlays:false];
            }
            
            if([self updateCanceled:updateId]){
                break;
            }
        }
        
        NSMutableDictionary * featureTables = [[NSMutableDictionary alloc] init];
        if(self.editFeaturesMode){
            // TODO edit feature mode
        }else{
            for(GPKGSDatabase * database in [self.active getDatabases]){
                NSArray * features = [database getFeatures];
                if([features count] > 0){
                    NSMutableArray * databaseFeatures = [[NSMutableArray alloc] init];
                    [featureTables setObject:databaseFeatures forKey:database.name];
                    for(GPKGSTable * features in [database getFeatures]){
                        [databaseFeatures addObject:features.name];
                    }
                }
            }
        }
        
        for(NSString * databaseName in [featureTables allKeys]){
            
            if(count >= maxFeatures){
                break;
            }
            
            NSMutableArray * databaseFeatures = [featureTables objectForKey:databaseName];
            
            for(NSString * features in databaseFeatures){
                count = [self displayFeaturesWithId:updateId andDatabase:databaseName andFeatures:features andCount:count andMaxFeatures:maxFeatures];
                if([self updateCanceled:updateId] || count >= maxFeatures){
                    break;
                }
            }
            
            if([self updateCanceled:updateId]){
                break;
            }
        }
    }
    
    if(self.boundingBox != nil){
        [self.mapView addOverlay:self.boundingBox];
    }
    
    if(zoom){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self zoomToActive];
        });
    }
    
    return count;
}

-(void) zoomToActive{
    
    GPKGBoundingBox * bbox = self.featuresBoundingBox;
    
    float paddingPercentage;
    if(bbox == nil){
        bbox = self.tilesBoundingBox;
        if(self.featureOverlayTiles){
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURE_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }else{
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }
    }else{
        paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURES_ZOOM_PADDING_PERCENTAGE] intValue] * .01f;
    }
    
    if(bbox != nil){

        struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
        double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
        double expandedWidth = size.width + (2 * (size.width * paddingPercentage));
        
        CLLocationCoordinate2D center = [bbox getCenter];
        MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);
        
        double latitudeRange = expandedRegion.span.latitudeDelta / 2.0;
        double longitudeRange = expandedRegion.span.longitudeDelta / 2.0;
        
        if(expandedRegion.center.latitude + latitudeRange > 90.0 || expandedRegion.center.latitude - latitudeRange < -90.0
           || expandedRegion.center.longitude + longitudeRange > 180.0 || expandedRegion.center.longitude - longitudeRange < -180.0){
            expandedRegion = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
        }
        
        [self.mapView setRegion:expandedRegion animated:true];
    }
}

-(void) displayTiles: (GPKGSTileTable *) tiles{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:tiles.database];
    
    GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tiles.name];
    
    MKTileOverlay * overlay = [GPKGOverlayFactory getTileOverlayWithTileDao:tileDao];
    overlay.canReplaceMapContent = false;
    
    GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
    GPKGContents * contents = [[geoPackage getTileMatrixSetDao] getContents:tileMatrixSet];
    
    [self displayTilesWithOverlay:overlay andGeoPackage:geoPackage andContents:contents andSpecifiedBoundingBox:nil];
}

-(void) displayFeatureTiles: (GPKGSFeatureOverlayTable *) featureOverlay{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:featureOverlay.database];
    
    GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureOverlay.featureTable];
    
    GPKGBoundingBox * boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:featureOverlay.minLon andMaxLongitudeDouble:featureOverlay.maxLon andMinLatitudeDouble:featureOverlay.minLat andMaxLatitudeDouble:featureOverlay.maxLat];
    
    // Load tiles
    GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
    
    GPKGFeatureIndexer * indexer = [[GPKGFeatureIndexer alloc] initWithFeatureDao:featureDao];
    [featureTiles setIndexQuery:[indexer isIndexed]];
    
    [featureTiles setPointColor:featureOverlay.pointColor];
    [featureTiles setPointRadius:featureOverlay.pointRadius];
    [featureTiles setLineColor:featureOverlay.lineColor];
    [featureTiles setLineStrokeWidth:featureOverlay.lineStroke];
    [featureTiles setPolygonColor:featureOverlay.polygonColor];
    [featureTiles setPolygonStrokeWidth:featureOverlay.polygonStroke];
    [featureTiles setFillPolygon:featureOverlay.polygonFill];
    if(featureTiles.fillPolygon){
        [featureTiles setPolygonFillColor:featureOverlay.polygonFillColor];
    }
    
    [featureTiles calculateDrawOverlap];
    
    GPKGFeatureOverlay * overlay = [[GPKGFeatureOverlay alloc] initWithFeatureTiles:featureTiles];
    [overlay setBoundingBox:boundingBox withProjection:[GPKGProjectionFactory getProjectionWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
    [overlay setMinZoom:[NSNumber numberWithInt:featureOverlay.minZoom]];
    [overlay setMaxZoom:[NSNumber numberWithInt:featureOverlay.maxZoom]];
    
    GPKGGeometryColumns * geometryColumns = featureDao.geometryColumns;
    GPKGContents * contents = [[geoPackage getGeometryColumnsDao] getContents:geometryColumns];
    
    self.featureOverlayTiles = true;
    
    [self displayTilesWithOverlay:overlay andGeoPackage:geoPackage andContents:contents andSpecifiedBoundingBox:boundingBox];
}

-(void) displayTilesWithOverlay: (MKTileOverlay *) overlay andGeoPackage: (GPKGGeoPackage *) geoPackage andContents: (GPKGContents *) contents andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{
    
    GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
    GPKGProjection * projection = [contentsDao getProjection:contents];
    
    GPKGProjectionTransform * transformToWebMercator = [[GPKGProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
    
    GPKGBoundingBox * contentsBoundingBox = [contents getBoundingBox];
    if([projection.epsg intValue] == PROJ_EPSG_WORLD_GEODETIC_SYSTEM){
        contentsBoundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:contentsBoundingBox];
    }

    GPKGBoundingBox * webMercatorBoundingBox = [transformToWebMercator transformWithBoundingBox:contentsBoundingBox];
    GPKGProjectionTransform * transform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    GPKGBoundingBox * boundingBox = [transform transformWithBoundingBox:webMercatorBoundingBox];
    
    if(specifiedBoundingBox != nil){
        boundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:specifiedBoundingBox];
    }
    
    if(self.tilesBoundingBox == nil){
        self.tilesBoundingBox = boundingBox;
    }else{
        if([boundingBox.minLongitude compare:self.tilesBoundingBox.minLongitude] == NSOrderedAscending){
            [self.tilesBoundingBox setMinLongitude:boundingBox.minLongitude];
        }
        if([boundingBox.maxLongitude compare:self.tilesBoundingBox.maxLongitude] == NSOrderedDescending){
            [self.tilesBoundingBox setMaxLongitude:boundingBox.maxLongitude];
        }
        if([boundingBox.minLatitude compare:self.tilesBoundingBox.minLatitude] == NSOrderedAscending){
            [self.tilesBoundingBox setMinLatitude:boundingBox.minLatitude];
        }
        if([boundingBox.maxLatitude compare:self.tilesBoundingBox.maxLatitude] == NSOrderedDescending){
            [self.tilesBoundingBox setMaxLatitude:boundingBox.maxLatitude];
        }
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:overlay];
    });
}

-(int) displayFeaturesWithId: (int) updateId andDatabase: (NSString *) database andFeatures: (NSString *) features andCount: (int) count andMaxFeatures: (int) maxFeatures{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:database];
    GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:features];
    
    GPKGResultSet * results = [featureDao queryForAll];
    @try {
        while(![self updateCanceled:updateId] && count < maxFeatures && [results moveToNext]){
            GPKGFeatureRow * row = [featureDao getFeatureRow:results];
            count = [self processFeatureRowWithDatabase:database andFeatureDao:featureDao andFeatureRow:row andCount:count andMaxFeatures:maxFeatures];
        }
    }
    @finally {
        [results close];
    }
    
    return count;
}

-(int) processFeatureRowWithDatabase: (NSString *) database andFeatureDao: (GPKGFeatureDao *) featureDao andFeatureRow: (GPKGFeatureRow *) row andCount: (int) count andMaxFeatures: (int) maxFeatures{
    GPKGProjection * projection = featureDao.projection;
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:projection];
    
    GPKGGeometryData * geometryData = [row getGeometry];
    if(geometryData != nil && !geometryData.empty){
        
        WKBGeometry * geometry = geometryData.geometry;
        
        if(geometry != nil){
            if(count++ < maxFeatures){
                GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                [self updateFeatureBoundingBox:shape];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                });
            }
        }
        
    }
    return count;
}

-(void) updateFeatureBoundingBox: (GPKGMapShape *) shape
{
    if(self.featuresBoundingBox != nil){
        [shape expandBoundingBox:self.featuresBoundingBox];
    }else{
        self.featuresBoundingBox = [shape boundingBox];
    }
}

-(int) getMaxFeatures{
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    return maxFeatures;
}

- (void)downloadTilesViewController:(GPKGSDownloadTilesViewController *)controller downloadedTiles:(int)count withError: (NSString *) error{
    if(count > 0){
        
        GPKGSTable * table = [[GPKGSTileTable alloc] initWithDatabase:controller.databaseValue.text andName:controller.data.name andCount:0];
        [self.active addTable:table];
        
        [self updateInBackgroundWithZoom:false];
        [self.active setModified:true];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_CREATE_TILES_DIALOG_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error downloading tiles to table '%@' in database: '%@'\n\nError: %@", controller.data.name, controller.databaseValue.text, error]];
    }
}

- (void)selectFeatureTableViewController:(GPKGSSelectFeatureTableViewController *)controller database:(NSString *)database table: (NSString *) table request: (NSString *) request{
    
    if([request isEqualToString:GPKGS_MAP_SEG_EDIT_FEATURES_REQUEST]){
        // TODO
    }else if ([request isEqualToString:GPKGS_MAP_SEG_FEATURE_TILES_REQUEST]){
        // TODO
    }
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    self.internalSeg = true;
    
    if([segue.identifier isEqualToString:GPKGS_MAP_SEG_DOWNLOAD_TILES])
    {
        GPKGSDownloadTilesViewController *downloadTilesViewController = segue.destinationViewController;
        downloadTilesViewController.delegate = self;
        downloadTilesViewController.manager = self.manager;
        downloadTilesViewController.data = [[GPKGSCreateTilesData alloc] init];
        if(self.boundingBox != nil){
            double minLat = 90.0;
            double minLon = 180.0;
            double maxLat = -90.0;
            double maxLon = -180.0;
            for(int i = 0; i < self.boundingBox.pointCount; i++){
                MKMapPoint mapPoint = self.boundingBox.points[i];
                CLLocationCoordinate2D coord = MKCoordinateForMapPoint(mapPoint);
                minLat = MIN(minLat, coord.latitude);
                minLon = MIN(minLon, coord.longitude);
                maxLat = MAX(maxLat, coord.latitude);
                maxLon = MAX(maxLon, coord.longitude);
            }
            GPKGBoundingBox * bbox = [[GPKGBoundingBox alloc]initWithMinLongitudeDouble:minLon andMaxLongitudeDouble:maxLon andMinLatitudeDouble:minLat andMaxLatitudeDouble:maxLat];
            [downloadTilesViewController.data.loadTiles.generateTiles setBoundingBox:bbox];
        }
    } else if([segue.identifier isEqualToString:GPKGS_MAP_SEG_SELECT_FEATURE_TABLE]){
        GPKGSSelectFeatureTableViewController * selectFeatureTableViewController = segue.destinationViewController;
        selectFeatureTableViewController.delegate = self;
        selectFeatureTableViewController.manager = self.manager;
        selectFeatureTableViewController.active = self.active;
        selectFeatureTableViewController.request = self.segRequest;
    }
}

@end