//
//  MNSettings.m
//  Svátek
//
//  Created by Mirek Novak on 12.03.2023.
//

#import "MNSettings.h"

@interface MNSettings ()
@property (nonatomic) NSUserDefaults *userData;

@end

@implementation MNSettings

- (void)windowDidLoad {
    [super windowDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(IBAction)loginItemChange:(id)sender{
    bool state = [[self loginItemSwitch] state];
    NSLog(@" login item state changed %d",state);
}
-(IBAction)scanContactsChange:(id)sender{
    bool state = [[self contactsSwitch] state];
    NSLog(@" login item state changed %d",state);
}

-(void)setUserData:(NSUserDefaults *)userData{
    self.userData = [NSUserDefaults standardUserDefaults];
    
    if(self.loginItemSwitch != nil){
        
    }
}
-(void)windowWillClose:(NSNotification *)notification{
    NSLog(@"Closing window ...");
    [NSApp stopModal];
}

@end
