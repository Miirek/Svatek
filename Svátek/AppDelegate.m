//
//  AppDelegate.m
//  Svatek
//
//  Created by Mirek Novak on 01.03.2023. Refaktoring 2025-07
//

#import "AppDelegate.h"
#import "SettingsDialog.h"
#import <QuartzCore/QuartzCore.h>

@interface AppDelegate ()
@end

BOOL contacsRead = NO;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.smaService = [SMAppService mainAppService];
    SMAppServiceStatus result = [self.smaService status];

    self.contacts = [[CNContactStore alloc] init];
    self.notifications = [UNUserNotificationCenter currentNotificationCenter];
    [self.notifications getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        // Handle settings if needed
    }];

    // Setup UI first - this loads the name days from CSV
    [self setupStatusBarItem];

    CNAuthorizationStatus cnStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (cnStatus == CNAuthorizationStatusNotDetermined) {
        [self.contacts requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            NSLog(@"Contacts access: %@", granted ? @"granted" : @"denied");
            if (granted) {
                [self scanContactsMatchingNameDaysToDictionary];
            } else {
                // No permission, setup menu without contact matching
                [self setupMenu];
            }
        }];
    } else if(cnStatus == CNAuthorizationStatusAuthorized){
        NSLog(@"Contacts authorization: Authorized");
        [self scanContactsMatchingNameDaysToDictionary];
    } else {
        // Not authorized, setup menu without contact matching
        NSLog(@"Contacts not authorized, status: %ld", (long)cnStatus);
        [self setupMenu];
    }

    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(updateTitle:)
                                   userInfo:nil
                                    repeats:YES];

    NSLog(@"App started; service status: %ld", (long)result);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Cleanup
    [self stopGlowAnimation];
    [self stopLetterGlowAnimation];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)updateTitle:(id)sender {
    [self setupMenu];
}

- (void)setupStatusBarItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"MenuRose"];
    self.statusItem.button.image.prefersColorMatch = YES;
    self.statusItem.button.title = @"Svátek má ...";
    self.statusItem.button.image.template = YES;

    [self setupNameDays];
    NSLog(@"Status bar item set up!");
}

- (void)loadDefaultNameDays {
    NSError *error = nil;
    NSURL *svatkyUrl = [[NSBundle mainBundle] URLForResource:@"svatky" withExtension:@"csv"];
    NSString *fileContents = [NSString stringWithContentsOfURL:svatkyUrl encoding:NSUTF8StringEncoding error:&error];

    if (!fileContents) {
        NSLog(@"Chyba při načítání svátků: %@", error);
        return;
    }

    NSArray *rows = [fileContents componentsSeparatedByString:@"\r\n"];
    self.nameDays = [NSMutableDictionary dictionaryWithCapacity:rows.count];

    for (NSString *row in rows) {
        if (row.length == 0) continue;
        NSArray *columns = [row componentsSeparatedByString:@";"];
        if (columns.count != 2) continue;

        NSString *index = columns[1];
        NSString *name = columns[0];

        NSDictionary *existing = self.nameDays[index];
        NSString *existingName = existing[@"name"];

        if (existingName) {
            NSString *newName = [NSString stringWithFormat:@"%@ ∙ %@", existingName, name];
            self.nameDays[index] = @{ @"name": newName, @"date": index, @"hilite": @NO };
        } else {
            self.nameDays[index] = @{ @"name": name, @"date": index, @"hilite": @NO };
        }
    }
}

- (void)setupNameDays {
    if (![self loadUserPreferences]) {
        NSLog(@"Creating user preferences");
        [self loadDefaultNameDays];
        [[NSUserDefaults standardUserDefaults] setObject:self.nameDays forKey:@"nameDays"];
    }
}

- (BOOL)loadUserPreferences {
    return NO;
    self.nameDays = [[NSUserDefaults standardUserDefaults] objectForKey:@"nameDays"];
    if (self.nameDays) {
        NSLog(@"Loaded prefs: %lu names loaded", (unsigned long)self.nameDays.count);
        return YES;
    }
    NSLog(@"User preferences don't exist!");
    return NO;
}

- (void)about:(id)sender {
    NSString *copyright = [NSString stringWithFormat:@"Svátek v.%@, build:%@\n©️2025 Mirek",
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = copyright;
    [alert addButtonWithTitle:@"Budiž"];
    alert.informativeText = @"Ikona aplikace pochází z\nhttps://www.vecteezy.com/";
    [alert runModal];
}

- (void)tryRegisterLaunchLogin:(id)sender {
    SMAppServiceStatus status = [self.smaService status];
    NSError *error = nil;
    BOOL registered = NO;

    switch (status) {
        case SMAppServiceStatusNotFound:
            NSLog(@"WTF - status not found??");
            registered = [self.smaService registerAndReturnError:&error];
            break;
        case SMAppServiceStatusEnabled:
            [self.smaService unregisterAndReturnError:&error];
            break;
        case SMAppServiceStatusRequiresApproval:
            [[[NSAlert alloc] init] runModal];
            registered = [self.smaService registerAndReturnError:&error];
            break;
        default:
            break;
    }

    NSString *title = registered ? @"Spouštět při startu ✔️" : @"Spouštět při startu";
    if (!self.launchAtLogin) {
        self.launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:) keyEquivalent:@""];
    } else {
        self.launchAtLogin.title = title;
    }
    NSLog(@"Service status: %@ Status: %ld", title, (long)status);
}

- (void)setNamesForToday:(NSString *)todayStr dateFormatter:(NSDateFormatter *)dateFormat {
    if (!self.nameDays) {
        [self setupNameDays];
    }

    NSDictionary *todayEntry = self.nameDays[todayStr];
    if (!todayEntry) return;

    self.lastCheckDate = todayStr;
    self.todayName = todayEntry[@"name"];
    self.statusItem.button.title = self.todayName;

    // Check if any contacts match today's name day
    NSString *matchingContacts = [self getStringOfContactNamesForName:self.todayName];
    self.hilite = (matchingContacts.length > 0);
    self.statusItem.button.image.template = !self.hilite;

    // Start or stop glow animation based on matches
    if (self.hilite) {
        [self startGlowAnimation];
    } else {
        [self stopGlowAnimation];
    }

    NSDateComponents *deltaComps = [[NSDateComponents alloc] init];
    deltaComps.day = 1;
    NSString *tomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:[NSDate date] options:0]];
    self.tomorrowName = [NSString stringWithFormat:@"Zítra %@", self.nameDays[tomorrowStr][@"name"]];

    deltaComps.day = 2;
    NSString *afterTomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:[NSDate date] options:0]];
    self.dayAfterTomorrowName = [NSString stringWithFormat:@"Pozítří %@", self.nameDays[afterTomorrowStr][@"name"]];
}

- (void)setupMenu {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"M/d";
    NSString *todayStr = [dateFormat stringFromDate:[NSDate now]];

    if ([todayStr isEqualToString:self.lastCheckDate]) {
        SMAppServiceStatus status = [self.smaService status];
        NSString *title = (status == SMAppServiceStatusEnabled) ? @"Spouštět při startu ✔️" : @"Spouštět při startu";

        if (!self.launchAtLogin) {
            self.launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:) keyEquivalent:@""];
        } else {
            self.launchAtLogin.title = title;
        }
        return;
    }

    [self setNamesForToday:todayStr dateFormatter:dateFormat];

    // Build tooltip with matching contacts if found
    NSString *matchingContacts = [self getStringOfContactNamesForName:self.todayName];
    if (matchingContacts.length > 0) {
        self.statusItem.button.toolTip = [NSString stringWithFormat:@"Svátek má: %@\n\n%@", matchingContacts, self.tomorrowName];
    } else {
        self.statusItem.button.toolTip = self.tomorrowName;
    }

    SMAppServiceStatus status = [self.smaService status];
    NSString *title = (status == SMAppServiceStatusEnabled) ? @"Spouštět při startu ✔️" : @"Spouštět při startu";

    self.launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:) keyEquivalent:@""];
    self.tomorrowItem = [[NSMenuItem alloc] initWithTitle:self.tomorrowName action:nil keyEquivalent:@""];
    self.dayAfterTomorrowItem = [[NSMenuItem alloc] initWithTitle:self.dayAfterTomorrowName action:nil keyEquivalent:@""];

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItem:self.tomorrowItem];
    [menu addItem:self.dayAfterTomorrowItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:self.launchAtLogin];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"O aplikaci" action:@selector(about:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Zkontrolovat kontakty" action:@selector(scanContacts:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Ukončit" action:@selector(quit:) keyEquivalent:@""];

    self.statusItem.menu = menu;
}

- (void)quit:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

- (void)scanContacts:(id)sender {
    NSLog(@"Scanning contacs ...");
    [self scanContactsMatchingNameDaysToDictionary];
    
}

- (void)scanContactsMatchingNameDaysToDictionary {
    if (!self.nameDays) {
        [self setupNameDays];
    }

    // Scan in background process, dont block UI
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary<NSString *, NSString *> *normalizedNameMap = [NSMutableDictionary dictionary];
        for (NSDictionary *entry in [self.nameDays allValues]) {
            NSString *nameField = entry[@"name"];
            if (!nameField) continue;

            // Split by " ∙ " to match how names are joined in loadDefaultNameDays
            NSArray *names = [nameField componentsSeparatedByString:@" ∙ "];
            for (NSString *name in names) {
                NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (trimmed.length == 0) continue;
                NSString *normalized = [[trimmed stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]] lowercaseString];
                normalizedNameMap[normalized] = trimmed;
                NSLog(@"📝 Přidán svátek: '%@' -> normalized: '%@'", trimmed, normalized);
            }
        }

        NSMutableDictionary<NSString *, NSMutableArray<CNContact *> *> *matches = [NSMutableDictionary dictionary];
        NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];

        NSLog(@"Začínám skenování kontaktů. Celkem svátků: %lu", (unsigned long)normalizedNameMap.count);

        NSError *error = nil;
        BOOL success = [self.contacts enumerateContactsWithFetchRequest:request
                                                                 error:&error
                                                            usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            if (!contact.givenName || contact.givenName.length == 0) return;

            NSString *normalizedGiven = [[contact.givenName stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]] lowercaseString];

            NSString *originalName = normalizedNameMap[normalizedGiven];
            if (originalName) {
                if (!matches[originalName]) {
                    matches[originalName] = [NSMutableArray array];
                }
                [matches[originalName] addObject:contact];
                NSLog(@"Shoda! Kontakt: %@ %@ -> svátek: %@", contact.givenName, contact.familyName ?: @"", originalName);
            }
        }];

        if (!success || error) {
            NSLog(@"Chyba při načítání kontaktů: %@", error.localizedDescription);
        }
        
        contacsRead = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            self.matchedContactsByName = matches;
            NSLog(@"Načteno %lu svátečních jmen s odpovídajícími kontakty", (unsigned long)matches.count);

            // Force menu refresh to update tooltip and icon
            [self setupMenu];
        });
    });
}
-(NSString *) getStringOfContactNamesForName: (NSString *)name {
    NSMutableString *namesList = [[NSMutableString alloc] init];

    NSLog(@"Hledám kontakty pro svátek: '%@'", name);
    NSLog(@"   Celkem svátků v databázi: %lu", (unsigned long)self.matchedContactsByName.count);

    // Split the name by " ∙ " to handle multiple names on the same day
    NSArray *names = [name componentsSeparatedByString:@" ∙ "];

    for (NSString *singleName in names) {
        NSString *trimmedName = [singleName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<CNContact *> *contacts = self.matchedContactsByName[trimmedName];

        NSLog(@"   Kontroluji jméno: '%@' -> %lu kontaktů", trimmedName, (unsigned long)(contacts ? contacts.count : 0));

        if (contacts && contacts.count > 0) {
            for (CNContact *contact in contacts) {
                NSString *fullName = [NSString stringWithFormat:@"%@ %@", contact.givenName, contact.familyName ?: @""];
                if (namesList.length > 0) {
                    [namesList appendString:@", "];
                }
                [namesList appendString:fullName];
                NSLog(@"   +Přidán kontakt: %@", fullName);
            }
        }
    }

    NSLog(@"   Výsledek: '%@'", namesList.length > 0 ? namesList : @"(žádné shody)");
    return [namesList copy];
}

- (void)startGlowAnimation {
    // Stop any existing timer
    [self stopGlowAnimation];

    // Start a new timer that triggers every 60 seconds
    self.glowTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                      target:self
                                                    selector:@selector(performGlow:)
                                                    userInfo:nil
                                                     repeats:YES];
    // Trigger immediately for the first time
    [self.glowTimer fire];

    NSLog(@"✨ Glow animation started");
}

- (void)stopGlowAnimation {
    if (self.glowTimer) {
        [self.glowTimer invalidate];
        self.glowTimer = nil;
        NSLog(@"⏹ Glow animation stopped");
    }
}

- (void)performGlow:(NSTimer *)timer {
    if (!self.statusItem.button) return;

    NSLog(@"Performing glow animation");

    // Start the letter-by-letter glow animation
    [self startLetterGlowAnimation];
}

- (void)startLetterGlowAnimation {
    // Stop any existing letter animation
    [self stopLetterGlowAnimation];

    self.currentGlowIndex = -1;

    // Start a timer that animates each letter
    // Duration: 0.08 seconds per letter for smooth effect
    self.letterGlowTimer = [NSTimer scheduledTimerWithTimeInterval:0.08
                                                            target:self
                                                          selector:@selector(animateNextLetter:)
                                                          userInfo:nil
                                                           repeats:YES];

    NSLog(@"Letter glow animation started");
}

- (void)stopLetterGlowAnimation {
    if (self.letterGlowTimer) {
        [self.letterGlowTimer invalidate];
        self.letterGlowTimer = nil;

        // Reset to normal title
        if (self.statusItem.button && self.todayName) {
            self.statusItem.button.attributedTitle = nil;
            self.statusItem.button.title = self.todayName;
        }

        NSLog(@"Letter glow animation stopped");
    }
}

- (void)animateNextLetter:(NSTimer *)timer {
    if (!self.todayName || self.todayName.length == 0) {
        [self stopLetterGlowAnimation];
        return;
    }

    self.currentGlowIndex++;

    // If we've gone through all letters twice, stop
    if (self.currentGlowIndex >= self.todayName.length * 2) {
        [self stopLetterGlowAnimation];
        return;
    }

    // Get the actual index (wrap around for second pass)
    NSInteger actualIndex = self.currentGlowIndex % self.todayName.length;

    // Update the button with the glowing letter
    NSAttributedString *attrString = [self attributedStringWithGlowAtIndex:actualIndex];
    self.statusItem.button.attributedTitle = attrString;
}

- (NSAttributedString *)attributedStringWithGlowAtIndex:(NSInteger)index {
    if (!self.todayName || index < 0 || index >= self.todayName.length) {
        return [[NSAttributedString alloc] initWithString:self.todayName ?: @""];
    }

    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:self.todayName];

    // Default attributes - normal text
    NSDictionary *normalAttributes = @{
        NSForegroundColorAttributeName: [NSColor controlTextColor],
        NSFontAttributeName: [NSFont systemFontOfSize:0] // 0 = default size
    };

    // Glow attributes - brighter and with shadow
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = self.hilite ? [NSColor colorWithCalibratedRed:1.0 green:0.8 blue:0.0 alpha:1.0]
                                     : [NSColor whiteColor];
    shadow.shadowBlurRadius = 3.0;
    shadow.shadowOffset = NSMakeSize(0, 0);

    NSDictionary *glowAttributes = @{
        NSForegroundColorAttributeName: self.hilite ? [NSColor colorWithCalibratedRed:1.0 green:0.9 blue:0.0 alpha:1.0]
                                                    : [NSColor whiteColor],
        NSFontAttributeName: [NSFont boldSystemFontOfSize:0],
        NSShadowAttributeName: shadow
    };

    // Apply normal attributes to all
    [attrString setAttributes:normalAttributes range:NSMakeRange(0, self.todayName.length)];

    // Apply glow to the current letter
    [attrString setAttributes:glowAttributes range:NSMakeRange(index, 1)];

    return attrString;
}

@end
