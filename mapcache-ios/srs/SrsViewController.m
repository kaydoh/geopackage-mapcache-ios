//
//  SrsViewController.m
//  mapcache-ios
//
//  Created by Dan Barela on 12/7/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "SrsViewController.h"

@interface SrsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *srsNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *organizationLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordsysIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *definitionLabel;
@property (weak, nonatomic) IBOutlet UILabel *definition12_063Label;
@property (weak, nonatomic) IBOutlet UILabel *definition12_063TitleLabel;

@end

@implementation SrsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.srsNameLabel.text = self.srs.srsName;
    self.organizationLabel.text = self.srs.organization;
    self.coordsysIdLabel.text = [NSString stringWithFormat:@"%@", self.srs.organizationCoordsysId];
    self.descriptionLabel.text = self.srs.theDescription;
    self.definitionLabel.text = [self formatDefinition:self.srs.definition];
    if (self.srs.definition_12_163 != nil) {
        self.definition12_063Label.text = [self formatDefinition:self.srs.definition_12_163];
    } else {
        self.definition12_063TitleLabel.hidden = YES;
        self.definition12_063Label.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *) formatDefinition: (NSString *) definition {
    
    NSArray *components = [definition componentsSeparatedByString:@","];
    NSMutableString *formattedDefinition = [[NSMutableString alloc] init];
    
    NSMutableString *format = [[NSMutableString alloc] init];
    [format appendString:@"\n%@, "];
    int count = 1;
    for (NSString *component in components) {
        NSLog(@"%d", count);

        NSRange first = [component rangeOfComposedCharacterSequenceAtIndex:0];
        NSRange match = [component rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet] options:0 range:first];
        if (match.location != NSNotFound) {
            // codeString starts with a letter
            [formattedDefinition appendFormat:format, component];
            
        } else {
            [formattedDefinition appendFormat: @"%@, ", component];
        }
        
        NSRange rightRange = [component rangeOfString:@"]"];
        NSRange leftRange = [component rangeOfString:@"["];
        if ([component hasSuffix:@"]"]) {
            count -= ([component length]-rightRange.location);
            [format deleteCharactersInRange:NSMakeRange(1, ([component length]-rightRange.location))];
        }
        if (leftRange.length != 0) {
            count++;
            [format insertString:@"\t" atIndex:1];
        }
        
        
    }
    
    if ([formattedDefinition hasSuffix:@", "]) {
        [formattedDefinition deleteCharactersInRange:NSMakeRange([formattedDefinition length]-2, 2)];
    }
    
    //NSString *formattedDefinition = [self.srs.definition stringByReplacingOccurrencesOfString:@"," withString:@",\n\t"];
    
    return formattedDefinition;
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
