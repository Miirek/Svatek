//
//  SettingsDialog.m
//  Svátek
//
//  Created by Mirek Novak on 20.03.2023.
//

#import "SettingsDialog.h"

@interface SettingsDialog ()

@end

@implementation SettingsDialog

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
-(void)windowWillClose:(NSNotification *)notification{
    NSLog(@"Closing window ...");
    [NSApp stopModal];
}
@end
