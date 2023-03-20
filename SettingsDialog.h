//
//  SettingsDialog.h
//  Svátek
//
//  Created by Mirek Novak on 20.03.2023.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsDialog : NSWindowController
@property IBOutlet NSWindow *window;
@property (nonatomic, strong, readwrite) NSDictionary *nameDays;
@end

NS_ASSUME_NONNULL_END
