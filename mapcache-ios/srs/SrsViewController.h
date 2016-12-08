//
//  SrsViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 12/7/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GPKGSpatialReferenceSystem.h>

@interface SrsViewController : UIViewController

@property (strong, nonatomic) GPKGSpatialReferenceSystem *srs;

@end
