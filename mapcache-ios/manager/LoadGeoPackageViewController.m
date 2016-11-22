//
//  LoadGeoPackageViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 11/22/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "LoadGeoPackageViewController.h"
#import "GPKGGeoPackageManager.h"
#import <GPKGGeoPackageFactory.h>
#import "GPKGIOUtils.h"

@interface LoadGeoPackageViewController ()

@property (nonatomic) BOOL active;
@property (nonatomic, strong) NSNumber * progress;
@property (nonatomic, strong) NSNumber * maxProgress;

@end

@implementation LoadGeoPackageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
    
    self.active = true;
    self.progress = [NSNumber numberWithInt:0];
    self.progressView.hidden = false;
    self.progressView.progress = 0.0f;
    self.nameLabel.text = self.name;
    self.urlLabel.text = self.url;
    
    @try {
        NSURL *url = [NSURL URLWithString:self.url];
        [manager importGeoPackageFromUrl:url withName:[self.name stringByReplacingOccurrencesOfString:@" " withString:@"_"] andProgress:self];
    }
    @catch (NSException *e) {
        NSLog(@"Download File Error for url '%@' with error: %@", self.url, [e description]);
        [self failureWithError:[e description]];
    }@finally{
        [manager close];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) updateProgress{
    if(self.maxProgress != nil){
        float progress = [self.progress floatValue] / [self.maxProgress floatValue];
        [self.downloadLabel setText:[NSString stringWithFormat:@"( %@ of %@ )", [GPKGIOUtils formatBytes:[self.progress intValue]], [GPKGIOUtils formatBytes:[self.maxProgress intValue]]]];
        [self.progressView setProgress:progress];
    }
}

-(void) setMax: (int) max{
    self.maxProgress = [NSNumber numberWithInt:max];
    [self updateProgress];
}

-(void) addProgress: (int) progress{
    self.progress = [NSNumber numberWithInt:[self.progress intValue] + progress];
    [self updateProgress];
}

-(BOOL) cleanupOnCancel{
    return true;
}

-(BOOL) isActive{
    return self.active;
}

-(void) completed{
    NSLog(@"completed");
    /*
    if(self.delegate != nil){
        [self.delegate downloadFileViewController:self downloadedFile:true withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
     */
}

-(void) failureWithError: (NSString *) error{
    NSLog(@"error");
    /*
    NSString * errorMessage = error;
    if(self.delegate != nil){
        [self.delegate downloadFileViewController:self downloadedFile:false withError:errorMessage];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
     */
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
