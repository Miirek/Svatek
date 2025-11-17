//
//  AppDelegate.h
//  Svátek
//
//  Created by Mirek Novak on 01.03.2023.
//

#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>
#import <Contacts/Contacts.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMutableDictionary *nameDays;

@property (nonatomic, assign) BOOL hilite;
@property (nonatomic, strong) NSString *todayName;
@property (nonatomic, strong) NSString *tomorrowName;
@property (nonatomic, strong) NSString *dayAfterTomorrowName;
@property (nonatomic, strong) NSString *lastCheckDate;

@property (strong, nonatomic) NSMenuItem *launchAtLogin;
@property (strong, nonatomic) NSMenuItem *settings;
@property (strong, nonatomic) NSMenuItem *tomorrowItem;
@property (strong, nonatomic) NSMenuItem *dayAfterTomorrowItem;

@property (strong, nonatomic) SMAppService *smaService;
@property (strong, nonatomic) CNContactStore *contacts;
@property (strong, nonatomic) UNUserNotificationCenter *notifications;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<CNContact *> *> *matchedContactsByName;
@property (strong, nonatomic) NSTimer *glowTimer;
@property (strong, nonatomic) NSTimer *letterGlowTimer;
@property (nonatomic, assign) NSInteger currentGlowIndex;


- (void)setupStatusBarItem;
- (void)setupNameDays;
- (BOOL)loadUserPreferences;
- (void)loadDefaultNameDays;
- (void)setupMenu;
- (void)setNamesForToday:(NSString *)todayStr dateFormatter:(NSDateFormatter *)dateFormat;
- (void)about:(id)sender;
- (void)tryRegisterLaunchLogin:(id)sender;
- (void)scanContacts:(id)sender;
- (void)scanContactsMatchingNameDaysToDictionary;
- (NSString *)getStringOfContactNamesForName:(NSString *)name;
- (void)startGlowAnimation;
- (void)stopGlowAnimation;
- (void)performGlow:(NSTimer *)timer;
- (void)startLetterGlowAnimation;
- (void)stopLetterGlowAnimation;
- (void)animateNextLetter:(NSTimer *)timer;
- (NSAttributedString *)attributedStringWithGlowAtIndex:(NSInteger)index;

@end
