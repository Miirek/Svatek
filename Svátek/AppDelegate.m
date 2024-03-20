//
//  AppDelegate.m
//  Svátek
//
//  Created by Mirek Novak on 01.03.2023.
//
// ikona: https://www.vecteezy.com/vector-art/7528227-flower-icon-flower-rose-vector-design-illustration-flower-icon-simple-sign-rose-beauty-design
#import "AppDelegate.h"
#import <ServiceManagement/SMAppService.h>
#import <Contacts/Contacts.h>
#import <UserNotifications/UserNotifications.h>
#import "SettingsDialog.h"


@interface AppDelegate ()
@end

@implementation AppDelegate{
    
    NSStatusItem *statusItem;
    NSMutableDictionary *nameDays;
    bool hilite;
    
    NSString *todayName;
    NSString *tomorrowName;
    NSString *dayAfterTomorrowName;
    
    NSString *lastCheckDate;
    
    NSMenuItem *launchAtLogin;
    NSMenuItem *settings;
    NSMenuItem *tomorrowItem;
    NSMenuItem *dayAfterTomorrowItem; // TheDayAfterTomorrow Name

    SMAppService *smaService;
    
    CNContactStore *contacts;
    UNUserNotificationCenter *notifications;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    smaService = [SMAppService mainAppService];
    SMAppServiceStatus result = [smaService status];

    contacts = [[CNContactStore alloc] init];
    
    notifications = [UNUserNotificationCenter currentNotificationCenter];
    [notifications getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * settings) {
        NSLog(@"Settings: %@", settings);
    }];

    CNAuthorizationStatus cnStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    NSLog(@"Contacts %ld",cnStatus);
    [self setupStatusBarItem];
    [self setupMenu];
    [NSTimer scheduledTimerWithTimeInterval:60.0
        target:self
        selector:@selector(updateTitle:)
        userInfo:nil
        repeats:YES];
    NSError *error;
    NSLog(@"Error - %@; status: %ld ", error,result);

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

/** ------------------------------ ------------------------------ ------------------------------ ------------------------------ ------------------------------ ------------------------------ */

- (void)updateTitle:(id)sender {
    [self setupMenu];
}

-(void)scanContacts:(id)sender{
    [self contactScan];
}
-(void)setupStatusBarItem{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem.button.image = [NSImage imageNamed:@"MenuRose"];
    statusItem.button.image.prefersColorMatch = YES;
    [self setupNameDays];

    statusItem.button.title=@"Svátek má ...";
    [[[statusItem button]image] setTemplate:YES];

    [[[statusItem button] cell] setHighlighted:NO];
    
    // [[_statusItem button] setAction:@selector(itemClicked:)];
}

-(void)loadDefaultNameDays{
    NSError *error = nil;
    
    NSURL *svatkyUrl = [[NSBundle mainBundle] URLForResource:@"svatky" withExtension:@"csv"];
    NSString* fileContents = [NSString stringWithContentsOfURL:svatkyUrl encoding:NSUTF8StringEncoding error:&error];
    NSArray* rows = [fileContents componentsSeparatedByString:@"\r\n"];
    nameDays = [[NSMutableDictionary alloc ] initWithCapacity:rows.count];
    
    for (NSString *row in rows){
        NSArray* columns = [row componentsSeparatedByString:@";"];
        if([columns count] != 2) continue;
        NSString *index = columns[1];
        NSString *name = columns[0];
        NSString *existingName = [[nameDays objectForKey: index] objectForKey:@"name"];
        if(existingName != nil){
            NSString *newName = [NSString stringWithFormat:@"%@, %@",existingName, name];
            //[nameDays setObject:newName forKey:index];
            [nameDays setObject:
             [NSDictionary dictionaryWithObjectsAndKeys:
              newName,@"name",
              index,@"date",
              [NSNumber numberWithBool:NO],@"hilite",
              nil] forKey:index];
        }else{
            //[nameDays setObject:name forKey:index];
            [nameDays setObject:
             [NSDictionary dictionaryWithObjectsAndKeys:
              name,@"name",
              index,@"date",
              [NSNumber numberWithBool:NO],@"hilite",
              nil] forKey:index];
        }
    }
}

-(void)setupNameDays{
    if(![self loadUserPreferences]){
        NSLog(@"Creating user preferences");
        [self loadDefaultNameDays];
        [[NSUserDefaults standardUserDefaults] setObject:nameDays forKey:@"nameDays"];
    }
}

-(bool)loadUserPreferences{
    nameDays = [[NSUserDefaults standardUserDefaults] objectForKey:@"nameDays"];
    
    if(nameDays != nil){

        NSLog(@"Loaded prefs: %lu names loaded", (unsigned long)[nameDays count]);
        return YES;

    }     NSLog(@"User preferences doesnt exists!");
    return NO;
}

-(void)about:(id)sender{
    NSString *copyright =[NSString stringWithFormat:@"Svátek v.%@, build:%@\n©️2023 Mirek",
                          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
   
    NSAlert *simpleAlert = [[NSAlert alloc] init];
    [simpleAlert setMessageText:copyright];
    [simpleAlert addButtonWithTitle:@"Budiž"];
    [simpleAlert setInformativeText:@"Ikona aplikace pochází z\nhttps://www.vecteezy.com/"];
    
    [simpleAlert runModal];
}

-(void)tryRegisterLaunchLogin:(id)sender{
    SMAppServiceStatus status = [smaService status];
    NSLog(@"Status: %ld", (long)status);
    NSError *lastError;
    BOOL registered = NO;
    
    if (status == SMAppServiceStatusNotFound){
        NSLog(@"WTF - status not found??");
        NSLog(@"Will try to register service");
        NSError *error;
        if(!(registered = [smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            return;
        }
        NSLog(@"Service registered");


    }
    
    if(status == SMAppServiceStatusEnabled){
        NSLog(@"Unregistering service ...");
        if([smaService unregisterAndReturnError:&lastError]){
            NSLog(@"Deregistration failed. Reason: %@",lastError);
            return;
        }
        
        [[statusItem button] setKeyEquivalent:@""];
        NSLog(@"Service deregistered.");
    }
    
    if(status == SMAppServiceStatusRequiresApproval){
        NSLog(@"Will try to register service");

        NSAlert *simpleAlert = [[NSAlert alloc] init];
        [simpleAlert setMessageText:@"Budete požádán/a o svolení aktivace služby při startu."];
        [simpleAlert addButtonWithTitle:@"Rozumím"];
        [simpleAlert setInformativeText:@""];

        [simpleAlert runModal];
        
        NSError *error;
        if(!(registered = [smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            return;
        }
        NSLog(@"Service registered");
        return;
    }
    
    if(status == SMAppServiceStatusNotRegistered){
        NSLog(@"Will try to register service");
        NSError *error;
        if(!(registered = [smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            return;
        }
        NSLog(@"Service registered");
    }


    NSString *title = registered ? @"Spouštět při startu ✔️" : @"Spouštět při startu";
    
    if(launchAtLogin == nil){
        launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:)keyEquivalent:@""];
    }else{
        [launchAtLogin setTitle:title];
    }
    NSLog(@"Service status: %@ Status: %ld", title, status);

}

- (void) setNamesForToday:(NSString*)todayStr dateFormatter:(NSDateFormatter*) dateFormat{
    if(nameDays == nil){
        [self setupNameDays];
    }

    hilite = false;
    lastCheckDate = nil;
    lastCheckDate = [NSString stringWithString:todayStr];
    todayName = [[nameDays objectForKey:todayStr] objectForKey:@"name"];
    [[statusItem button] setTitle: todayName];
    
    hilite = [[nameDays objectForKey:todayStr] boolForKey:@"hilite"];
    [[[statusItem button]image] setTemplate:!hilite];
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    [deltaComps setDay:1];
    NSString* tomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps  toDate:[NSDate date] options:0]];
    tomorrowName = [NSString stringWithFormat:@"Zítra %@",[[nameDays objectForKey:tomorrowStr]objectForKey: @"name"]];

    [deltaComps setDay:2];
    NSString* afterTomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps  toDate:[NSDate date] options:0]];
    dayAfterTomorrowName = [NSString stringWithFormat:@"Pozítří %@",[[nameDays objectForKey:afterTomorrowStr] objectForKey: @"name"] ];

    nameDays = nil;
}

- (void)setupMenu{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"M/d"];
    NSString *todayStr = [dateFormat stringFromDate:[NSDate now]];
    
    if([todayStr isEqualToString:lastCheckDate]){
        SMAppServiceStatus status = [smaService status];
        NSString *title = (status == SMAppServiceStatusEnabled) ? @"Spouštět při startu  ✔️" : @"Spouštět při startu";
        NSLog(@"Service status: %ld", status);
        if(launchAtLogin == nil){
            launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:)keyEquivalent:@""];
        }else{
            [launchAtLogin setTitle:title];
        }
        NSLog(@"Already checked today.");
        return;
    }

    [self setNamesForToday:todayStr dateFormatter:dateFormat];
    
    statusItem.button.toolTip =  tomorrowName;
    
    SMAppServiceStatus status = [smaService status];
    NSString *title = (status == SMAppServiceStatusEnabled) ? @"Spouštět při startu  ✔️" : @"Spouštět při startu";
    NSLog(@"Service status: %ld", status);
    
    
    NSFont *font=[NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
    NSMutableAttributedString *attTomorrow = [[NSMutableAttributedString alloc] initWithString:tomorrowName];
    [attTomorrow beginEditing];
    [attTomorrow addAttribute:NSFontAttributeName value:font range:NSMakeRange(6, [tomorrowName length] - 6)];
    [attTomorrow addAttribute:NSForegroundColorAttributeName value:[NSColor systemRedColor] range:NSMakeRange(6, [tomorrowName length] - 6)];
    [attTomorrow endEditing];

    NSMutableAttributedString *attAfterTomorrow = [[NSMutableAttributedString alloc] initWithString:dayAfterTomorrowName];
    [attAfterTomorrow beginEditing];
    [attAfterTomorrow addAttribute:NSFontAttributeName value:font range:NSMakeRange(8, [dayAfterTomorrowName length] - 8)];
    [attAfterTomorrow addAttribute:NSForegroundColorAttributeName value:[NSColor systemOrangeColor] range:NSMakeRange(8, [dayAfterTomorrowName length] - 8)];
    [attAfterTomorrow endEditing];

    if(launchAtLogin == nil){
        launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:)keyEquivalent:@""];
    }else{
        [launchAtLogin setTitle:title];
    }

    if(tomorrowItem == nil){
        tomorrowItem = [[NSMenuItem alloc] initWithTitle:tomorrowName action:nil keyEquivalent:@""];
    }

    [tomorrowItem setAttributedTitle:attTomorrow];

    if(dayAfterTomorrowItem == nil){
        dayAfterTomorrowItem = [[NSMenuItem alloc] initWithTitle:dayAfterTomorrowName action:nil keyEquivalent:@""];
    }else{
        [dayAfterTomorrowItem setAttributedTitle:attAfterTomorrow];
        // we are only updating existing menu so we can leave ...
        return;
    }

    [dayAfterTomorrowItem setAttributedTitle:attAfterTomorrow];

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItem:tomorrowItem];
    [menu addItem:dayAfterTomorrowItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:launchAtLogin];
    [menu addItemWithTitle:@"Upozornit na svátky z kontaktů" action:@selector(scanContacts:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Nastavení" action:@selector(showSettingsDialog:) keyEquivalent:@""];
    [menu addItemWithTitle:@"O aplikaci" action:@selector(about:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Ukončit" action:@selector(quit:) keyEquivalent:@""];
    
    NSMenu *removed = statusItem.menu;
  
    statusItem.menu = menu;
    
//    [nameDays removeAllObjects];
//    nameDays = nil;
    
    removed = nil;
}

- (void) contactScan
{
    if ([CNContactStore class]) {
        CNEntityType entityType = CNEntityTypeContacts;
        if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined)
         {
             NSLog(@"Askinng for access rights for Contacts ...");
             NSAlert *simpleAlert = [[NSAlert alloc] init];
             [simpleAlert setMessageText:@"Budete požádán/a o svolení k přístupu k Vašim kontaktům.\nAplikace je projde a uloží si pouze seznam křestních jmen,\n na která vás, v den svátku, upozorní notifikací."];
             [simpleAlert addButtonWithTitle:@"Rozumím"];
             [simpleAlert setInformativeText:@""];

             [simpleAlert runModal];

             CNContactStore * contactStore = contacts;
             [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
                 if(granted){
                     [self getAllContact];
                 }else{
                     NSLog(@"No accass granted! %@",error);
                 }
             }];
         }
        else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusAuthorized)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
            {
                [self getAllContact];
            });
            
        }else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusDenied){
            NSLog(@"Access to contacs denied!");
        }
    }
}

-(void)getAllContact
{
    NSLog(@"Getting contacts ....");
    if([CNContactStore class])
    {
        NSError* contactError;
        CNContactStore* addressBook = [[CNContactStore alloc]init];
        [addressBook containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]] error:&contactError];
        NSArray * keysToFetch =@[CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPostalAddressesKey];
        CNContactFetchRequest * request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
        
        BOOL success = [addressBook enumerateContactsWithFetchRequest:request error:&contactError usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop){
            [self parseContactWithContact:contact];
        }];
        if(!success){
            NSLog(@"Contact reading failed, reason: %@", contactError);
        }
    }
}

- (void)parseContactWithContact :(CNContact* )contact
{
    NSString * firstName =  contact.givenName;
    NSString * lastName =  contact.familyName;
//    NSString * phone = [[contact.phoneNumbers valueForKey:@"value"] valueForKey:@"digits"];
//    NSString * email = [contact.emailAddresses valueForKey:@"value"];
//    NSArray * addrArr = [self parseAddressWithContac:contact];
    
    NSLog(@"First name: %@ [%@]", firstName,lastName);

}

- (NSMutableArray *)parseAddressWithContac: (CNContact *)contact
{
    NSMutableArray * addrArr = [[NSMutableArray alloc]init];
    CNPostalAddressFormatter * formatter = [[CNPostalAddressFormatter alloc]init];
    NSArray * addresses = (NSArray*)[contact.postalAddresses valueForKey:@"value"];
    if (addresses.count > 0) {
        for (CNPostalAddress* address in addresses) {
            [addrArr addObject:[formatter stringFromPostalAddress:address]];
        }
    }
    return addrArr;
}

- (void)showSettings:(id)sender{
    SettingsDialog *settingsDlg = [[SettingsDialog alloc] initWithWindowNibName:@"SettingsDialog" owner:self];
//    MNSettings *settingsDlg = [[MNSettings alloc]  initWithWindowNibName:NSStringFromClass([self class])];
    NSWindow *settingsWindow = [settingsDlg window];
    [NSApp runModalForWindow:settingsWindow];
    NSLog(@"Modal sheet ended!");
    
    [NSApp endSheet:settingsWindow];
    
}

- (void)quit:(id)sender{
    [[NSApplication sharedApplication] terminate:self];
}

-(void) showSettingsDialog:(id)sender{
    SettingsDialog *settingsDlg = [[SettingsDialog alloc]  initWithWindowNibName:@"SettingsDialog"];
//    MNSettings *settingsDlg = [[MNSettings alloc]  initWithWindowNibName:NSStringFromClass([self class])];
    if(!nameDays){
        [self setupNameDays];
    }
    [settingsDlg setNameDays: nameDays];
    NSWindow *settingsWindow = [settingsDlg window];
    [NSApp runModalForWindow:settingsWindow];
    NSLog(@"Modal sheet ended!");
    
    [NSApp endSheet:settingsWindow];
}

@end
