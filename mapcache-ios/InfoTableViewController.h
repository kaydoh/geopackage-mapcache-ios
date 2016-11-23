//
//  InfoTableViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 11/23/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabase.h"

@interface InfoTableViewController : UITableViewController

@property (strong, nonatomic) GPKGSDatabase *database;

@end
