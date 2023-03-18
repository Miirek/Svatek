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

#import "MNSvatek.h"
#import "MNStartup.h"
#import "MNSettings.h"

@interface AppDelegate ()

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMutableDictionary *nameDays;

@property (strong, nonatomic) NSString *today;
@property (strong, nonatomic) NSString *tomorrow;
@property (strong, nonatomic) NSString *dayAfterTomorrow;

@property (strong, nonatomic) NSString *lastCheckDate;

@property (strong, nonatomic) NSMenuItem *launchAtLogin;
@property (strong, nonatomic) NSMenuItem *tomorrowName;
@property (strong, nonatomic) NSMenuItem *tdatName; // TheDayAfterTomorrow Name

@property (strong, nonatomic) CNContactStore *contacts;
@property (strong, nonatomic) UNUserNotificationCenter *notifications;
@property (strong, nonatomic) MNSvatek *svatek;

@end

@implementation AppDelegate{
@protected
    MNStartup *startupService;

    
    
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    
    NSLog(@"%s called", __PRETTY_FUNCTION__);
    if(_svatek == nil){
        _svatek = [[MNSvatek alloc] init];
    }
 
    if ([NSEvent modifierFlags] == NSEventModifierFlagShift) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"DefaultsResetText", nil) defaultButton:NSLocalizedString(@"Cancel", nil) alternateButton:NSLocalizedString(@"OK", nil) otherButton:nil informativeTextWithFormat:NSLocalizedString(@"DefaultsResetDescription", nil)];
        NSInteger returnCode = [alert runModal];
        
        if (returnCode == NSAlertAlternateReturn) {
//            [[self svatek] resetDefaultSettings];
        }
    }
            
 //   [[self svatek] loadDefaultSettings];
    // other setup...
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"%s called", __PRETTY_FUNCTION__);
    startupService = [[MNStartup alloc] init];
        
    _contacts = [[CNContactStore alloc] init];
    _notifications = [UNUserNotificationCenter currentNotificationCenter];
    [_notifications getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * settings) {
        NSLog(@"Settings: %@", settings);
    }];

    CNAuthorizationStatus cnStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    NSLog(@"Contacts %ld",cnStatus);
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.image = [NSImage imageNamed:@"MenuRose"];
    _statusItem.button.image.prefersColorMatch = YES;
    [self setupNameDays];

    _statusItem.button.title=@"Svátek má ...";
    [_statusItem.button.image setTemplate:YES];

    _statusItem.button.cell.highlighted = NO;
    
    // [[_statusItem button] setAction:@selector(itemClicked:)];
    
    [self setupMenu];
    [NSTimer scheduledTimerWithTimeInterval:60.0
        target:self
        selector:@selector(updateTitle:)
        userInfo:nil
        repeats:YES];
    NSError *error;
    NSLog(@"Error - %@; status: %d ", error,[startupService isRegistered]);

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
    _nameDays = [[NSMutableDictionary alloc ] initWithCapacity:rows.count];
    
    for (NSString *row in rows){
        NSArray* columns = [row componentsSeparatedByString:@";"];
        [_nameDays setObject:columns[0] forKey:columns[1]];
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
    SMAppServiceStatus status = [_smaService status];
    NSLog(@"Status: %ld", (long)status);
    NSError *lastError;
    BOOL registered = NO;
    
    if (status == SMAppServiceStatusNotFound){
        NSLog(@"WTF - status not found??");
        NSLog(@"Will try to register service");
        NSError *error;
        if(!(registered = [_smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            return;
        }
        NSLog(@"Service registered");


    }
    
    if(status == SMAppServiceStatusEnabled){
        NSLog(@"Unregistering service ...");
        if([[self smaService] unregisterAndReturnError:&lastError]){
            NSLog(@"Deregistration failed. Reason: %@",lastError);
            return;
        }
        
        [[_statusItem button] setKeyEquivalent:@""];
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
        if(!(registered = [_smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            return;
        }
        NSLog(@"Service registered");
        return;
    }
    
    if(status == SMAppServiceStatusNotRegistered){
        NSLog(@"Will try to register service");
        NSError *error;
        if(!(registered = [_smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            return;
        }
        NSLog(@"Service registered");
    }


    NSString *title = registered ? @"Spouštět při startu ✔️" : @"Spouštět při startu";
    
    if(_launchAtLogin == nil){
        _launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:)keyEquivalent:@""];
    }else{
        [_launchAtLogin setTitle:title];
    }
    NSLog(@"Service status: %@ Status: %ld", title, status);

}

- (void)setupMenu{
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"M/d"];
    NSString *todayStr = [dateFormat stringFromDate:[NSDate now]];
    
    if([todayStr isEqualToString:_lastCheckDate]){
        SMAppServiceStatus status = [_smaService status];
        NSString *title = (status == SMAppServiceStatusEnabled) ? @"Spouštět při startu  ✔️" : @"Spouštět při startu";
        NSLog(@"Service status: %ld", status);
        if(_launchAtLogin == nil){
            _launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:)keyEquivalent:@""];
        }else{
            [_launchAtLogin setTitle:title];
        }
        NSLog(@"Already checked today.");
        return;
    }
    
    if(_nameDays == nil){
        [self setupNameDays];
    }
    
    _lastCheckDate = nil;
    _lastCheckDate = [NSString stringWithString:todayStr];
    _today = [_nameDays objectForKey:todayStr];
    _statusItem.button.title=_today;

    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    [deltaComps setDay:1];
    NSString* tomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps  toDate:[NSDate date] options:0]];
    _tomorrow = [NSString stringWithFormat:@"Zítra %@",[_nameDays objectForKey:tomorrowStr]];
    _statusItem.button.toolTip =  _tomorrow;
    [deltaComps setDay:2];
    NSString* afterTomorrowStr = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:deltaComps  toDate:[NSDate date] options:0]];
    _dayAfterTomorrow = [NSString stringWithFormat:@"Pozítří %@",[_nameDays objectForKey:afterTomorrowStr]];
    
    SMAppServiceStatus status = [_smaService status];
    NSString *title = (status == SMAppServiceStatusEnabled) ? @"Spouštět při startu  ✔️" : @"Spouštět při startu";
    NSLog(@"Service status: %ld", status);
    
    
    NSFont *font=[NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
    NSMutableAttributedString *attTomorrow = [[NSMutableAttributedString alloc] initWithString:_tomorrow];
    [attTomorrow beginEditing];
    [attTomorrow addAttribute:NSFontAttributeName value:font range:NSMakeRange(6, [_tomorrow length] - 6)];
    [attTomorrow addAttribute:NSForegroundColorAttributeName value:[NSColor systemRedColor] range:NSMakeRange(6, [_tomorrow length] - 6)];
    [attTomorrow endEditing];

    NSMutableAttributedString *attAfterTomorrow = [[NSMutableAttributedString alloc] initWithString:_dayAfterTomorrow];
    [attAfterTomorrow beginEditing];
    [attAfterTomorrow addAttribute:NSFontAttributeName value:font range:NSMakeRange(8, [_dayAfterTomorrow length] - 8)];
    [attAfterTomorrow addAttribute:NSForegroundColorAttributeName value:[NSColor systemOrangeColor] range:NSMakeRange(8, [_dayAfterTomorrow length] - 8)];
    [attAfterTomorrow endEditing];

    if(_launchAtLogin == nil){
        _launchAtLogin = [[NSMenuItem alloc] initWithTitle:title action:@selector(tryRegisterLaunchLogin:)keyEquivalent:@""];
    }else{
        [_launchAtLogin setTitle:title];
    }

    if(_tomorrowName == nil){
        _tomorrowName = [[NSMenuItem alloc] initWithTitle:_tomorrow action:nil keyEquivalent:@""];
    }

    [_tomorrowName setAttributedTitle:attTomorrow];

    if(_tdatName == nil){
        _tdatName = [[NSMenuItem alloc] initWithTitle:_dayAfterTomorrow action:nil keyEquivalent:@""];
    }else{
        [_tdatName setAttributedTitle:attAfterTomorrow];
        // we are only updating existing menu so we can leave ...
        return;
    }

    [_tdatName setAttributedTitle:attAfterTomorrow];

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItem:_tomorrowName];
    [menu addItem:_tdatName];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:_launchAtLogin];
//    [menu addItemWithTitle:@"Upozornit na svátky z kontaktů" action:@selector(scanContacts:) keyEquivalent:@""];
    [menu addItemWithTitle:@"O aplikaci" action:@selector(about:) keyEquivalent:@""];
    
    __strong NSMenuItem *preferences = [[NSMenuItem alloc] init];
    [preferences setTarget:[self svatek]];
    [preferences setAction:@selector(showSettingsDialog:)];
    [preferences setTitle:@"Nastavení..."];
    [preferences setKeyEquivalent:@""];
 //   [menu addItem:preferences];
                //   WithTitle:@"Nastavení" action:@selector(showSettingsDialog:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    
    [menu addItemWithTitle:@"Ukončit" action:@selector(quit:) keyEquivalent:@""];
    
    NSMenu *removed = _statusItem.menu;
  
    _statusItem.menu = menu;
    
    [_nameDays removeAllObjects];
    _nameDays = nil;
    
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

             CNContactStore * contactStore = _contacts;
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
