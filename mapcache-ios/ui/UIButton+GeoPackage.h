//
//  UIButton+GeoPackage.h
//  mapcache-ios
//
//  Created by Dan Barela on 11/17/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabase.h"

@interface UIButton (GeoPackage)

@property (nonatomic, retain) GPKGSDatabase *geoPackage;

@end
