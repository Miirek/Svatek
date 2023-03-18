//
//  MNStartup.h
//  Svátek
//
//  Created by Mirek Novak on 07.03.2023.
//

#import <Foundation/Foundation.h>
#import <ServiceManagement/SMAppService.h>

NS_ASSUME_NONNULL_BEGIN

@interface MNStartup : NSObject{
    @protected
        SMAppServiceStatus smaStatus;
    
}
@property (nonatomic, readonly) BOOL isRegistered;

-(id) init;
-(bool) registerLoginItem;
-(bool) unregisterLoginItem;

@end

NS_ASSUME_NONNULL_END
