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
    NSMenuItem *tomorrowItem;
    NSMenuItem *tdaTomorrowItem;
    
    NSMenuItem *aboutItem;
    NSMenuItem *settingsItem;
    NSMenuItem *quit;
}

@property (readwrite) BOOL shouldStartAtLogin;
@property (readwrite) BOOL canScanContacts;

-(void) showSettingsDialog:(id)sender;
-(void) resetDefaultSettings;
-(void) loadDefaultSettings;
-(NSUserDefaults *) loadSettings;

-(void) startup;
@end

NS_ASSUME_NONNULL_END
