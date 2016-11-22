//
//  LoadGeoPackageViewController.h
//  mapcache-ios
//
//  Created by Dan Barela on 11/22/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGProgress.h"
#import "GPKGSDownloadFileViewController.h"

@interface LoadGeoPackageViewController : UIViewController <GPKGProgress>

@property (nonatomic, weak) id <GPKGSDownloadFileDelegate> delegate;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *name;
@property (weak, nonatomic) IBOutlet UILabel *downloadLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;

@end
