//
//  FeatureTableTableViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 12/1/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "FeatureTableTableViewController.h"
#import "GPKGFeatureDao.h"
#import "GPKGSTableCell.h"
#import "GPKGSConstants.h"
#import <GPKGFeatureTable.h>
#import "UITableViewHeaderFooterView+GeoPackage.h"

@interface FeatureTableTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *featureTableNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfFeaturesLabel;
@property (weak, nonatomic) GPKGFeatureDao *featureDao;
@property (weak, nonatomic) GPKGFeatureTable *featureTable;

@end

@implementation FeatureTableTableViewController

/*
- (void) setGeoPackage:(GPKGGeoPackage *)geoPackage {
    _geoPackage = geoPackage;
    self.featureDao = [self.geoPackage getFeatureDaoWithTableName: self.table.name];
    [self.featureDao initializeColumnIndex];
}
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    self.featureTableNameLabel.text = self.table.name;
    self.numberOfFeaturesLabel.text = [NSString stringWithFormat:@"%d Features", self.table.count];
    self.featureTable = [self.dao getFeatureTable];

//    self.featureDao = [self.geoPackage getFeatureDaoWithTableName: self.table.name];
//    [self.dao initializeColumnIndex];
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 || section == 1) {
        return 1;
    } else {
        
        return [self.featureTable columns].count;
    }
    return 0;
}
//return [self.tileTablesExpanded ? @"\u25bc " : @"\u25b6 " stringByAppendingString:@"Tile Tables"];
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Spatial Reference System";
    } else if (section == 1) {
        return @"Geometry Column";
    } else if (section == 2) {
        return @"Columns";
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    //GPKGSDatabase * database = (GPKGSDatabase *) [self.databases valueForKey:[self.databaseNames objectAtIndex:section]];
    
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *hfv = (UITableViewHeaderFooterView *) view;
        [hfv.textLabel setTextColor:[UIColor colorWithRed:144.0f/256.0f green:201.0f/256.0f blue:216.0f/256.0f alpha:1.0f]];
        hfv.data = [NSNumber numberWithInteger:section];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerClicked:)];
        [hfv addGestureRecognizer:tap];
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
    /*
    if ([section isEqualToNumber:[NSNumber numberWithInt:1]]) {
        self.tileTablesExpanded = !self.tileTablesExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([section isEqualToNumber:[NSNumber numberWithInt:2]]) {
        self.featureTablesExpanded = !self.featureTablesExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([section isEqualToNumber:[NSNumber numberWithInt:3]]) {
        self.spatialReferenceSystemsExpanded = !self.spatialReferenceSystemsExpanded;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    */
}

- (void) headerButtonClick: (UIButton *) button {
    
    //[self performSegueWithIdentifier:@"showGeoPackageInfo" sender:button.geoPackage];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        GPKGSTableCell *cell = (GPKGSTableCell *)[tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_SRS forIndexPath:indexPath];
        
        NSNumber *srsId = self.dao.geometryColumns.srsId;
        GPKGSpatialReferenceSystem *srs = (GPKGSpatialReferenceSystem *)[[self.geoPackage getSpatialReferenceSystemDao] queryForIdObject:srsId];
                
        cell.tableName.text = [NSString stringWithFormat:@"%@ %@", srs.srsName, srs.srsId];
        return cell;
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ColumnCell" forIndexPath:indexPath];
        cell.textLabel.text = @"geom column name";
        cell.detailTextLabel.text = @"geom type";
        return cell;
    } else if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ColumnCell" forIndexPath:indexPath];
        
        GPKGUserColumn *row = (GPKGUserColumn *)[[self.featureTable columns] objectAtIndex:indexPath.row];
        cell.textLabel.text = row.name;
        cell.detailTextLabel.text = [GPKGDataTypes name:[row dataType]];
        return cell;
    }
    return nil;
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
