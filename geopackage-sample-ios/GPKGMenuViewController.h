//
//  GPKGMenuViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/2/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GPKGMenuDrawerViewController;

@interface GPKGMenuViewController : UITableViewController

@property(nonatomic, weak) GPKGMenuDrawerViewController* menuDrawerViewController;

@end
