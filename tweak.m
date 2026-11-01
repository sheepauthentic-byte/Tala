// Language: Objective-C
// File: tweak.m
// Runtime: iOS / UIKit / Foundation / Objective-C Runtime
// Target: aovnet.framework (kgvn)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static id hooked_SafeUUID(id self, SEL _cmd) {
    return [[NSUUID alloc] initWithUUIDString:@"E621E1F8-C36C-495A-93FC-0C247A3E6E5F"];
}

static BOOL hooked_ReturnYES(id self, SEL _cmd) {
    return YES;
}

static BOOL hooked_ReturnNO(id self, SEL _cmd) {
    return NO;
}

static void initDylibBypass(void) {
    @autoreleasepool {
        Class devClass = [UIDevice class];
        SEL idfvSel = @selector(identifierForVendor);
        Method idfvMethod = class_getInstanceMethod(devClass, idfvSel);
        if (idfvMethod) {
            class_replaceMethod(devClass, idfvSel, (IMP)hooked_SafeUUID, method_getTypeEncoding(idfvMethod));
        }

        const char *targetClasses[] = {
            "ASClientInfo",
            "ASDebugSessionManager",
            "DTTJailbreakDetection",
            "ASStatusView"
        };

        for (size_t i = 0; i < sizeof(targetClasses) / sizeof(targetClasses[0]); i++) {
            Class cls = objc_getClass(targetClasses[i]);
            if (!cls) continue;

            class_replaceMethod(cls, sel_registerName("isAuthorized"), (IMP)hooked_ReturnYES, "B@:");
            class_replaceMethod(cls, sel_registerName("isActivated"), (IMP)hooked_ReturnYES, "B@:");
            class_replaceMethod(cls, sel_registerName("isJailbroken"), (IMP)hooked_ReturnNO, "B@:");
        }
    }
}

__attribute__((constructor)) static void dylibEntry(void) {
    initDylibBypass();
}
