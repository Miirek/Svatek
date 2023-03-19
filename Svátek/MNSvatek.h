//
//  MNSvatek.h
//  Svátek
//
//  Created by Mirek Novak on 07.03.2023.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MNSvatek : NSObject{
    NSStatusItem *barItem;
    
    NSMenuItem *tomorrowItem;
    NSMenuItem *tdaTomorrowItem;
    
    NSMenuItem *aboutItem;
    NSMenuItem *settingsItem;
    NSMenuItem *quit;
}

@property (nonatomic, readwrite) BOOL shouldStartAtLogin;
@property (nonatomic,readwrite) BOOL canScanContacts;
@property (readwrite) NSString *todayName;
@property (readwrite) NSString *tomorrowName;
@property (readwrite) NSString *afterTomorrowName;

-(void) showSettingsDialog:(id)sender;

-(void) resetDefaultSettings;
-(void) loadDefaultSettings;
-(NSUserDefaults *) loadSettings;

-(void) setUpMenu;

-(void) startup;
@end

NS_ASSUME_NONNULL_END
