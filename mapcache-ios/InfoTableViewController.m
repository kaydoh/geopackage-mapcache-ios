//
//  InfoTableViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 11/23/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "InfoTableViewController.h"
#import "GeneralInfoTableViewCell.h"
#import "GPKGGeoPackage.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSTableCell.h"
#import "GPKGSConstants.h"
#import "UITableViewHeaderFooterView+GeoPackage.h"

@interface InfoTableViewController ()

@property GPKGGeoPackage *geoPackage;
@property BOOL tileTablesExpanded;
@property BOOL featureTablesExpanded;

@end

@implementation InfoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tileTablesExpanded = YES;
    self.featureTablesExpanded = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger rows = [self tablesInSection:section];
    if (section == 0) {
        return nil;
    } else if (section == 1) {
        if (rows != 0) {
            return [self.tileTablesExpanded ? @"\u25b2 " : @"\u25bc " stringByAppendingString:@"Tile Tables"];
        } else {
            return @"Tile Tables";
        }
    } else if (section == 2) {
        if (rows != 0) {
            return [self.featureTablesExpanded ? @"\u25b2 " : @"\u25bc " stringByAppendingString:@"Feature Tables"];
        } else {
            return @"Feature Tables";
        }
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    return UITableViewAutomaticDimension;
}

-(NSInteger) tablesInSection: (NSInteger) section {
    if (section == 1) {
        return [self.geoPackage getTileTableCount];
    } else if (section == 2) {
        return [self.geoPackage getFeatureTableCount];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return self.tileTablesExpanded ? [self tablesInSection:section] : 0;
    } else if (section == 2) {
        return self.featureTablesExpanded ? [self tablesInSection:section] : 0;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        GeneralInfoTableViewCell *cell = (GeneralInfoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"general" forIndexPath:indexPath];
        [cell setupCellWithGeoPackage:self.geoPackage];
    
        return cell;
    } else if (indexPath.section == 1) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_TILE_TABLE forIndexPath:indexPath];
        
        return cell;
    } else if (indexPath.section == 2) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_FEATURE_TABLE forIndexPath:indexPath];
    
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 120.0f;
    } else {
        return 44.0f;
    }
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    //GPKGSDatabase * database = (GPKGSDatabase *) [self.databases valueForKey:[self.databaseNames objectAtIndex:section]];
    
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *) view;
        [hfv.textLabel setTextColor:[UIColor colorWithRed:208.0f/256.0f green:234.0f/256.0f blue:221.0f/256.0f alpha:1.0f]];
        hfv.data = [NSNumber numberWithInteger:section];
        NSInteger rows = [self tablesInSection:section];
        if (rows == 0) {
            /*
            hfv.detailTextLabel.text = @"No tables of this type exist in this GeoPackage";
            [hfv.detailTextLabel setTextColor: [UIColor colorWithRed:255.0f/256.0f green:221.0f/256.0f blue:160.0f/256.0f alpha:1.0f]];
             */
        } else {
            //hfv.detailTextLabel.text = nil;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerClicked:)];
            [hfv addGestureRecognizer:tap];
        }
    }
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    //addButton.geoPackage = self.geoPackage;
    [addButton setTintColor:[UIColor colorWithRed:144.0f/256.0f green:201.0f/256.0f blue:216.0f/256.0f alpha:1.0f]];
    [addButton addTarget:self action:@selector(headerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:addButton];
    
    
    // Place button on far right margin of header
    addButton.translatesAutoresizingMaskIntoConstraints = NO; // use autolayout constraints instead
    [addButton.trailingAnchor constraintEqualToAnchor:view.layoutMarginsGuide.trailingAnchor].active = YES;
    [addButton.bottomAnchor constraintEqualToAnchor:view.layoutMarginsGuide.bottomAnchor].active = YES;
}

- (void) headerClicked: (UIGestureRecognizer *) sender {
    UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *)sender.view;
    NSNumber *section = (NSNumber *)hfv.data;
    if ([section isEqualToNumber:[NSNumber numberWithInt:1]]) {
        self.tileTablesExpanded = !self.tileTablesExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([section isEqualToNumber:[NSNumber numberWithInt:2]]) {
        self.featureTablesExpanded = !self.featureTablesExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) headerButtonClick: (UIButton *) button {
    
    //[self performSegueWithIdentifier:@"showGeoPackageInfo" sender:button.geoPackage];
}

- (void) setDatabase:(GPKGSDatabase *)database {
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    self.geoPackage = [manager open:database.name];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
