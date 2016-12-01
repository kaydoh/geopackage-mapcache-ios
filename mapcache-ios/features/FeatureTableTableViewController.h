//
//  FeatureTableTableViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 12/1/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GPKGSFeatureTable.h"
#import "GPKGSDatabase.h"
#import <GPKGGeoPackage.h>

@interface FeatureTableTableViewController : UITableViewController

@property (strong, nonatomic) GPKGSFeatureTable *table;
@property (strong, nonatomic) GPKGSDatabase *database;
@property (weak, nonatomic) GPKGGeoPackage *geoPackage;
@property (strong, nonatomic) GPKGFeatureDao *dao;

@end
