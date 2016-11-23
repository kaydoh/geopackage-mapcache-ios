//
//  GPKGSDownloadFileViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/9/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDownloadFileViewController.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGIOUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSUtils.h"
#import "LoadGeoPackageViewController.h"

@interface GPKGSDownloadFileViewController ()

@property (nonatomic) BOOL active;
@property (nonatomic, strong) NSNumber * progress;
@property (nonatomic, strong) NSNumber * maxProgress;
@property (nonatomic) int exampleToLoad;
@property (nonatomic, strong) NSArray *urls;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loadButton;

@end

@implementation GPKGSDownloadFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.loadButton setEnabled:NO];
    self.exampleToLoad = -1;
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.nameTextField.inputAccessoryView = keyboardToolbar;
    self.urlTextField.inputAccessoryView = keyboardToolbar;
}

- (void)viewWillAppear:(BOOL)animated {
    self.urls = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS];
    
    CGFloat tableHeight = 45.0f;
    tableHeight *= [self.urls count];
    
    self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.frame.size.width, self.exampleTable.frame.origin.y + tableHeight);
    
    self.exampleTable.frame = CGRectMake(self.exampleTable.frame.origin.x, self.exampleTable.frame.origin.y, self.exampleTable.frame.size.width, tableHeight);
    
    self.contentHeight.constant = self.tableOrigin.constant + tableHeight;
}

- (void) doneButtonPressed {
    [self.nameTextField resignFirstResponder];
    [self.urlTextField resignFirstResponder];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *example = [self.urls objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"example-gp-cell" forIndexPath:indexPath];
    cell.textLabel.text = [example objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_LABEL];
    cell.detailTextLabel.text = [example objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_URL];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.exampleToLoad != -1) {
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.exampleToLoad inSection:0]].accessoryType = UITableViewCellAccessoryNone;
    }
    self.exampleToLoad = (int)indexPath.row;
    NSDictionary *url = [self.urls objectAtIndex:self.exampleToLoad];
    [self.nameTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_LABEL]];
    [self.urlTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_URL]];
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [self updateImportButtonState];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.urls count];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"loadGeoPackageSegue"]) {
        LoadGeoPackageViewController *dest = [segue destinationViewController];
        [dest setName:self.nameTextField.text];
        [dest setUrl:self.urlTextField.text];
    }
}

- (IBAction)nameChanged:(id)sender {
    [self updateImportButtonState];
}

- (IBAction)urlChanged:(id)sender {
    [self updateImportButtonState];
}

-(void) updateImportButtonState{
    if([self.nameTextField.text length] == 0 || [self.urlTextField.text length] == 0){
        [self.loadButton setEnabled:NO];
    }else{
        [self.loadButton setEnabled:YES];
    }
}

@end
