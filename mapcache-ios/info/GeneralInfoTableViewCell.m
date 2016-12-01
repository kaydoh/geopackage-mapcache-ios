//
//  GeneralInfoTableViewCell.m
//  mapcache-ios
//
//  Created by Dan Barela on 11/23/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "GeneralInfoTableViewCell.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeoPackageFactory.h"

@implementation GeneralInfoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setupCellWithGeoPackage: (GPKGGeoPackage *) geoPackage {
    self.nameLabel.text = geoPackage.name;
    self.sizeLabel.text = @"2.3MB";
    
    NSArray *tileLayers = [geoPackage getTileTables];
    NSUInteger tileLayerCount = tileLayers.count;
    self.tileLayersLabel.text = [NSString stringWithFormat:@"%lu Tile Layers", (unsigned long)tileLayerCount];
    if (tileLayerCount == 0) {
        [self.tileLayersLabel setHidden:YES];
    }
    
    NSUInteger featureLayerCount = [geoPackage getFeatureTables].count;
    self.featureLayersLabel.text = [NSString stringWithFormat:@"%lu Feature Layers", (unsigned long)featureLayerCount];
    if (featureLayerCount == 0) {
        [self.featureLayersLabel setHidden:YES];
    }
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    self.sizeLabel.text = [manager readableSize:geoPackage.name];
    
    // create the overview image for the geopackage...
    
}

@end
