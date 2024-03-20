//
//  SettingsDialog.h
//  Svátek
//
//  Created by Mirek Novak on 20.03.2023.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsDialog : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, strong, readwrite) NSDictionary *nameDays;
@property IBOutlet NSTableView *nameDaysTableView;
@property IBOutlet NSTableCellView *name;
@property IBOutlet NSTableCellView *date;
@property IBOutlet NSTableCellView *checked;

@property (nonatomic) NSArray *names;
@property (nonatomic) NSArray *days;
@property (nonatomic) NSArray *hilites;
@end

NS_ASSUME_NONNULL_END

