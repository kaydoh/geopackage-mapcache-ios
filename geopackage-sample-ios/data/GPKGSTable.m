//
//  GPKGTable.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTable.h"

@implementation GPKGSTable

-(enum GPKGSTableType) getType{
    [self doesNotRecognizeSelector:_cmd];
    return GPKGS_TT_FEATURE;
}

@end