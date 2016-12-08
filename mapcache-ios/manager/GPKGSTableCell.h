//
//  GPKGSTableCell.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSActiveTableSwitch.h"
#import "GPKGSTableOptionsButton.h"
#import "GPKGSTable.h"
#import <GPKGBaseDao.h>
#import <GPKGGeoPackage.h>
#import <GPKGSpatialReferenceSystem.h>

@interface GPKGSTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet GPKGSActiveTableSwitch *active;
@property (weak, nonatomic) IBOutlet UIImageView *tableType;
@property (nonatomic, strong) IBOutlet UILabel *tableName;
@property (weak, nonatomic) IBOutlet UILabel *count;
@property (weak, nonatomic) IBOutlet GPKGSTableOptionsButton *optionsButton;
@property (strong, nonatomic) GPKGSTable *table;
@property (strong, nonatomic) GPKGBaseDao *dao;
@property (strong, nonatomic) GPKGGeoPackage *geoPackage;
@property (strong, nonatomic) GPKGSpatialReferenceSystem *srs;

@end
