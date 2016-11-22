//
//  UIButton+GeoPackage.m
//  mapcache-ios
//
//  Created by Dan Barela on 11/17/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "UIButton+GeoPackage.h"
#import <objc/runtime.h>

@implementation UIButton (GeoPackage)

static char UIB_GEOPACKGE_KEY;

@dynamic geoPackage;

-(void) setGeoPackage:(GPKGSDatabase *)geoPackage {
    objc_setAssociatedObject(self, &UIB_GEOPACKGE_KEY, geoPackage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSObject*) geoPackage {
    return (GPKGSDatabase *)objc_getAssociatedObject(self, &UIB_GEOPACKGE_KEY);
}

@end
