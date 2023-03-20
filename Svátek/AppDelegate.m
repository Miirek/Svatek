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



@interface AppDelegate ()
@end

@implementation AppDelegate{
    
    NSStatusItem *statusItem;
    NSMutableDictionary *nameDays;
    
    NSString *today;
    NSString *tomorrow;
    NSString *dayAfterTomorrow;
    
    NSString *lastCheckDate;
    
    NSMenuItem *launchAtLogin;
    NSMenuItem *tomorrowName;
    NSMenuItem *tdatName; // TheDayAfterTomorrow Name
    
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
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem.button.image = [NSImage imageNamed:@"MenuRose"];
    statusItem.button.image.prefersColorMatch = YES;
    [self setupNameDays];

    statusItem.button.title=@"Svátek má ...";
    [[[statusItem button]image] setTemplate:YES];

    [[[statusItem button] cell] setHighlighted:NO];
    
    // [[_statusItem button] setAction:@selector(itemClicked:)];
    
    [self setupMenu];
    [NSTimer scheduledTimerWithTimeInterval:60.0
        target:self
        selector:@selector(updateTitle:)
        userInfo:nil
        repeats:YES];
    NSError *error;
    NSLog(@"Error - %@; status: %ld ", error,result);

}

- (void)updateTitle:(id)sender {
    [self setupMenu];
}

-(void)scanContacts:(id)sender{
    [self contactScan];
}

-(void)setupNameDays{
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
        NSString *existingName = [nameDays objectForKey: index];
        if(existingName != nil){
            NSString *newName = [NSString stringWithFormat:@"%@, %@",existingName, name];
            [nameDays setObject:newName forKey:index];
        }else
            [nameDays setObject:name forKey:index];
    }
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
    
    if(nameDays == nil){
        [self setupNameDays];
    }
    
    lastCheckDate = nil;
    lastCheckDate = [NSString stringWithString:todayStr];
    today = [nameDays objectForKey:todayStr];
    [[statusItem button] setTitle: today];

    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    [deltaComps setDay:1];
    NSString* tomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps  toDate:[NSDate date] options:0]];
    tomorrow = [NSString stringWithFormat:@"Zítra %@",[nameDays objectForKey:tomorrowStr]];
    statusItem.button.toolTip =  tomorrow;
    [deltaComps setDay:2];
    NSString* afterTomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps  toDate:[NSDate date] options:0]];
    dayAfterTomorrow = [NSString stringWithFormat:@"Pozítří %@",[nameDays objectForKey:afterTomorrowStr]];
    
    SMAppServiceStatus status = [smaService status];
    NSString *title = (status == SMAppServiceStatusEnabled) ? @"Spouštět při startu  ✔️" : @"Spouštět při startu";
    NSLog(@"Service status: %ld", status);
    
    
    NSFont *font=[NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
    NSMutableAttributedString *attTomorrow = [[NSMutableAttributedString alloc] initWithString:tomorrow];
    [attTomorrow beginEditing];
    [attTomorrow addAttribute:NSFontAttributeName value:font range:NSMakeRange(6, [tomorrow length] - 6)];
    [attTomorrow addAttribute:NSForegroundColorAttributeName value:[NSColor systemRedColor] range:NSMakeRange(6, [tomorrow length] - 6)];
    [attTomorrow endEditing];

    NSMutableAttributedString *attAfterTomorrow = [[NSMutableAttributedString alloc] initWithString:dayAfterTomorrow];
    [attAfterTomorrow beginEditing];
    [attAfterTomorrow addAttribute:NSFontAttributeName value:font range:NSMakeRange(8, [dayAfterTomorrow length] - 8)];
    [attAfterTomorrow addAttribute:NSForegroundColorAttributeName value:[NSColor systemOrangeColor] range:NSMakeRange(8, [tomorrow length] - 8)];
    [attAfterTomorrow endEditing];

    if(launchAtLogin == nil){
        launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:)keyEquivalent:@""];
    }else{
        [launchAtLogin setTitle:title];
    }

    if(tomorrowName == nil){
        tomorrowName = [[NSMenuItem alloc] initWithTitle:tomorrow action:nil keyEquivalent:@""];
    }

    [tomorrowName setAttributedTitle:attTomorrow];

    if(tdatName == nil){
        tdatName = [[NSMenuItem alloc] initWithTitle:dayAfterTomorrow action:nil keyEquivalent:@""];
    }else{
        [tdatName setAttributedTitle:attAfterTomorrow];
        // we are only updating existing menu so we can leave ...
        return;
    }

    [tdatName setAttributedTitle:attAfterTomorrow];

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItem:tomorrowName];
    [menu addItem:tdatName];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:launchAtLogin];
    [menu addItemWithTitle:@"Upozornit na svátky z kontaktů" action:@selector(scanContacts:) keyEquivalent:@""];
    [menu addItemWithTitle:@"O aplikaci" action:@selector(about:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Ukončit" action:@selector(quit:) keyEquivalent:@""];
    
    NSMenu *removed = statusItem.menu;
  
    statusItem.menu = menu;
    
    [nameDays removeAllObjects];
    nameDays = nil;
    
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
            [self getAllContact];
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


- (void)quit:(id)sender{
    [[NSApplication sharedApplication] terminate:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
