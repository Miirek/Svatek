//
//  MNSettings.h
//  Svátek
//
//  Created by Mirek Novak on 12.03.2023.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MNSettings : NSWindowController
    @property (nonatomic,strong)IBOutlet NSSwitch *loginItemSwitch;
    @property (nonatomic,strong)IBOutlet NSSwitch *contactsSwitch;

-(void)setUserDefaults:(NSUserDefaults *)data;
@end

NS_ASSUME_NONNULL_END
