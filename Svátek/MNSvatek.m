//
//  MNSvatek.m
//  Svátek
//
//  Created by Mirek Novak on 07.03.2023.
//

#import "MNSvatek.h"
#import "MNSettings.h"

 NSString * const KEY_SHOULD_START_AT_LOGIN = @"startOnLogin";
 NSString * const KEY_READ_CONTACTS = @"scanContacts";

@implementation MNSvatek

    @dynamic canScanContacts;
    @dynamic shouldStartAtLogin;

- (void)loadDefaultSettings
{
    NSLog(@"Loading default settings from bundle config");
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"]];
    NSLog(@"Preferences loaded ...");

    [self setShouldStartAtLogin:[[defaults valueForKey:KEY_SHOULD_START_AT_LOGIN] boolValue]];
    [self setCanScanContacts:[[defaults valueForKey:KEY_READ_CONTACTS] boolValue]];
    
    NSLog(@"Saving Preferences ...");
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithDictionary:defaults]];
    NSLog(@"Default setting saved");
}

- (void)resetDefaultSettings
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *bundleIdentifer = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *persistentDomain = [userDefaults persistentDomainForName:bundleIdentifer];
    for (NSString *key in [persistentDomain allKeys]) {
        [userDefaults removeObjectForKey:key];
    }
}

-(NSUserDefaults *)loadSettings{
    __strong NSUserDefaults *settings = [NSUserDefaults standardUserDefaults] ;
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:KEY_SHOULD_START_AT_LOGIN] == nil) {
        [self loadDefaultSettings];
        return settings;
    }
    
    [self setCanScanContacts:[[settings valueForKey:KEY_READ_CONTACTS] boolValue]];
    [self setShouldStartAtLogin:[[settings valueForKey:KEY_SHOULD_START_AT_LOGIN] boolValue]];
    
    return settings;
}

-(void)setShouldStartAtLogin:(BOOL)state{
    self.shouldStartAtLogin = state;
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:KEY_SHOULD_START_AT_LOGIN];
    
}

-(void)setCanScanContacts:(BOOL)canScanContacts{
    self.canScanContacts = canScanContacts;
    [[NSUserDefaults standardUserDefaults] setBool:canScanContacts forKey:KEY_READ_CONTACTS];
}
-(void)startup{
    
}

-(void) showSettingsDialog:(id)sender{
    MNSettings *settingsDlg = [[MNSettings alloc]  initWithWindowNibName:@"MNSettings"];
//    MNSettings *settingsDlg = [[MNSettings alloc]  initWithWindowNibName:NSStringFromClass([self class])];
    NSWindow *settingsWindow = [settingsDlg window];
    [NSApp runModalForWindow:settingsWindow];
    NSLog(@"Modal sheet ended!");
    
    [NSApp endSheet:settingsWindow];
}
@end
