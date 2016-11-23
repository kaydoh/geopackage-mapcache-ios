//
//  GeneralInfoTableViewCell.h
//  mapcache-ios
//
//  Created by Dan Barela on 11/23/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGGeoPackage.h"

@interface GeneralInfoTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tileLayersLabel;
@property (weak, nonatomic) IBOutlet UILabel *featureLayersLabel;

- (void) setupCellWithGeoPackage: (GPKGGeoPackage *) geoPackage;

@end
