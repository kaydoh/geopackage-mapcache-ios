//
//  TileTableTableViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 12/5/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTileTable.h"
#import <GPKGGeoPackage.h>
#import <GPKGTileDao.h>

@interface TileTableTableViewController : UITableViewController

@property (strong, nonatomic) GPKGSTileTable *table;
@property (strong, nonatomic) GPKGGeoPackage *geoPackage;
@property (strong, nonatomic) GPKGTileDao *dao;

@end
