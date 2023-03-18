//
//  MNStartup.m
//  Svátek
//
//  Created by Mirek Novak on 07.03.2023.
//

#import "MNStartup.h"
#import <Cocoa/Cocoa.h>

@implementation MNStartup {
    SMAppService *smaService;
}

-(id)init{
    self = [super init];
    smaService = [SMAppService mainAppService];
    smaStatus = [smaService status];
    return self;
}

-(bool) registerLoginItem{
    bool success = NO;
    smaStatus = [smaService status];
    NSLog(@"Status: %ld", (long)smaStatus);
    NSError *lastError;
    
    
    if (smaStatus == SMAppServiceStatusNotFound){
        NSLog(@"WTF - status not found??");
        NSLog(@"Will try to register service");
        NSError *error;
        if(!(success = [smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            smaStatus = SMAppServiceStatusNotRegistered;

            return success;
        }
        NSLog(@"Service registered");
        smaStatus = SMAppServiceStatusEnabled;
        return success;
    }
        
    if(smaStatus == SMAppServiceStatusRequiresApproval){
        NSLog(@"Will try to register service");

        NSAlert *simpleAlert = [[NSAlert alloc] init];
        [simpleAlert setMessageText:@"Budete požádán/a o svolení aktivace služby při startu."];
        [simpleAlert addButtonWithTitle:@"Rozumím"];
        [simpleAlert setInformativeText:@""];

        [simpleAlert runModal];
        
        NSError *error;
        if(!(success = [smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            smaStatus = SMAppServiceStatusNotRegistered;

            return false;
        }
        NSLog(@"Service registered");
        smaStatus = SMAppServiceStatusEnabled;
        return success;
    }
    
    if(smaStatus == SMAppServiceStatusNotRegistered){
        NSLog(@"Will try to register service");
        NSError *error;
        if(!(success = [smaService registerAndReturnError:&error])){
            NSLog(@"Registration failed! Reason: %@", error);
            smaStatus = SMAppServiceStatusNotRegistered;
            return success;
        }
        smaStatus = SMAppServiceStatusEnabled;
        NSLog(@"Service registered");
        return success;
    }
    return success;
}

-(bool) unregisterLoginItem{
    bool success = NO;
    NSError *lastError;
    smaStatus = [smaService status];
    if(smaStatus == SMAppServiceStatusEnabled){
        NSLog(@"Unregistering service ...");
        if((success = [smaService unregisterAndReturnError:&lastError])){
            NSLog(@"Deregistration failed. Reason: %@",lastError);
            
            return success;
        }
        smaStatus = SMAppServiceStatusNotRegistered;
        NSLog(@"Service deregistered.");
    }

    return success;
}

-(bool) isRegistered{
    bool registered = NO;
    smaStatus = [smaService status];
    NSLog(@"Property called!");
    return smaStatus == SMAppServiceStatusEnabled;
}
@end
