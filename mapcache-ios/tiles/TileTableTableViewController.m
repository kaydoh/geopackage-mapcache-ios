//
//  TileTableTableViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 12/5/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "TileTableTableViewController.h"
#import "UITableViewHeaderFooterView+GeoPackage.h"
#import "GPKGSTableCell.h"
#import "GPKGSConstants.h"
#import <GPKGDataColumnsDao.h>
#import <GPKGProjectionTransform.h>
#import <GPKGProjectionConstants.h>
#import "SrsViewController.h"

@interface TileTableTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *tableNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *geoPackageNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *tileCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *minZoomLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxZoomLabel;
@property (weak, nonatomic) IBOutlet UILabel *xBoundsLabel;
@property (weak, nonatomic) IBOutlet UILabel *yBoundsLabel;

@property (strong, nonatomic) GPKGDataColumnsDao *dcDao;
@property (strong, nonatomic) NSMutableDictionary *collapsedSections;

@end

@implementation TileTableTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Tile Table";
    self.tableNameLabel.text = [NSString stringWithFormat:@"%@", self.table.name];
    self.geoPackageNameLabel.text = [NSString stringWithFormat:@"GeoPackage: %@", self.geoPackage.name];
    
    self.minZoomLabel.text = [NSString stringWithFormat: @"Min Zoom: %d", self.dao.minZoom];
    self.maxZoomLabel.text = [NSString stringWithFormat: @"Max Zoom: %d", self.dao.maxZoom];
    self.tileCountLabel.text = [NSString stringWithFormat:@"%d Tiles", [self.table count]];
    
    GPKGProjectionTransform * projectionToWebMercator = [[GPKGProjectionTransform alloc] initWithFromProjection:self.dao.projection andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    
    GPKGBoundingBox *box = [self.dao.tileMatrixSet getBoundingBox];
    GPKGBoundingBox *espg4326box = [projectionToWebMercator transformWithBoundingBox:box];
    self.xBoundsLabel.text = [NSString stringWithFormat:@"Longitude: %.2f to %.2f", [espg4326box.minLongitude doubleValue], [espg4326box.maxLongitude doubleValue]];
    self.yBoundsLabel.text = [NSString stringWithFormat:@"Latitude: %.2f to %.2f", [espg4326box.minLatitude doubleValue], [espg4326box.maxLatitude doubleValue]];
    
    self.collapsedSections = [[NSMutableDictionary alloc] init];
    self.dcDao = [self.geoPackage getDataColumnsDao];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL collpased = [(NSNumber *)[self.collapsedSections objectForKey:[NSNumber numberWithInteger:section]] boolValue];
    if (collpased) return 0;
    
    if (section == 0) {
        return 1;
    }
    if (section == 1) {
        return self.dao.columns.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_SRS forIndexPath:indexPath];
        
        NSNumber *srsId = self.dao.tileMatrixSet.srsId;
        GPKGSpatialReferenceSystem *srs = (GPKGSpatialReferenceSystem *)[[self.geoPackage getSpatialReferenceSystemDao] queryForIdObject:srsId];
        cell.srs = srs;
        cell.tableName.text = [NSString stringWithFormat:@"%@ %@", srs.srsName, srs.srsId];
        return cell;
    } else if (indexPath.section == 1) {
        
        GPKGUserColumn *row = [[self.dao getTileTable] getColumnWithColumnName:[self.dao.columns objectAtIndex: indexPath.row]];
        
        //GPKGUserColumn *row = (GPKGUserColumn *)[[self.featureTable columns] objectAtIndex:indexPath.row];
        GPKGDataColumns *dc = [self.dcDao getDataColumnByTableName:self.table.name andColumnName:row.name];
        
        if (dc == nil) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ColumnCell" forIndexPath:indexPath];
            cell.textLabel.text = row.name;
            cell.detailTextLabel.text = [GPKGDataTypes name:[row dataType]];
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DataColumnCell" forIndexPath:indexPath];
            
            ((UILabel *)[cell viewWithTag:4]).text = row.name;
            ((UILabel *)[cell viewWithTag:1]).text = [GPKGDataTypes name:[row dataType]];
            ((UILabel *)[cell viewWithTag:2]).text = dc.name;
            ((UILabel *)[cell viewWithTag:3]).text = dc.theDescription;
            return cell;
        }
    }
    
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 2) return UITableViewAutomaticDimension;
    
    GPKGUserColumn *row = [[self.dao getTileTable] getColumnWithColumnName:[self.dao.columns objectAtIndex: indexPath.row]];
    GPKGDataColumns *dc = [self.dcDao getDataColumnByTableName:self.table.name andColumnName:row.name];
    
    if (dc != nil) {
        return 118.0f;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *arrow = [(NSNumber *)[self.collapsedSections objectForKey:[NSNumber numberWithInteger:section]] boolValue] ? @"\u25b6 " : @"\u25bc ";
    if (section == 0) {
        return [arrow stringByAppendingString:@"Spatial Reference System"];
    } else if (section == 1) {
        return [arrow stringByAppendingString:@"Columns"];
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *) view;
        [hfv.textLabel setTextColor:[UIColor colorWithRed:144.0f/256.0f green:201.0f/256.0f blue:216.0f/256.0f alpha:1.0f]];
        hfv.data = [NSNumber numberWithInteger:section];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerClicked:)];
        [hfv addGestureRecognizer:tap];
    }
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    //addButton.geoPackage = self.geoPackage;
    [addButton setTintColor:[UIColor colorWithRed:144.0f/256.0f green:201.0f/256.0f blue:216.0f/256.0f alpha:1.0f]];
    [addButton addTarget:self action:@selector(headerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:addButton];
    
    
    // Place button on far right margin of header
    addButton.translatesAutoresizingMaskIntoConstraints = NO; // use autolayout constraints instead
    [addButton.trailingAnchor constraintEqualToAnchor:view.layoutMarginsGuide.trailingAnchor].active = YES;
    [addButton.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor].active = YES;
}

- (void) headerClicked: (UIGestureRecognizer *) sender {
    UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *)sender.view;
    NSNumber *section = (NSNumber *)hfv.data;
    BOOL collapsed = ![(NSNumber *)[self.collapsedSections objectForKey:section] boolValue];
    
    [self.collapsedSections setObject:[NSNumber numberWithBool:collapsed] forKey:section];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:[section longValue]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) headerButtonClick: (UIButton *) button {
    
    //[self performSegueWithIdentifier:@"showGeoPackageInfo" sender:button.geoPackage];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"srsTableSegue"]) {
        SrsViewController *vc = (SrsViewController *)[segue destinationViewController];
        GPKGSTableCell *cell = (GPKGSTableCell *)sender;
        [vc setSrs:cell.srs];
    }
}


@end
