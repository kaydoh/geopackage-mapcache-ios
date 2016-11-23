//
//  UITableViewHeaderFooterView+GeoPackage.h
//  mapcache-ios
//
//  Created by Dan Barela on 11/18/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabase.h"

@interface UITableViewHeaderFooterView (GeoPackage)

@property (nonatomic, retain) GPKGSDatabase *geoPackage;
@property (nonatomic, retain) NSObject *data;

@end
