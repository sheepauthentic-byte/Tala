#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <objc/message.h>

static id hooked_FakeUDID(id self, SEL _cmd) {
    return @"00008110-001A2B3C4D5E6F00";
}

static id hooked_FakeIDFV(id self, SEL _cmd) {
    return @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F";
}

static id hooked_FakeIDFVWithCache(id self, SEL _cmd, BOOL *status) {
    if (status) {
        *status = YES;
    }
    return @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F";
}

static BOOL hooked_ReturnNO(id self, SEL _cmd) {
    return NO;
}

static BOOL hooked_ReturnYES(id self, SEL _cmd) {
    return YES;
}

static int hooked_ActivationState(id self, SEL _cmd) {
    return 1;
}

static void hooked_NoOp(id self, SEL _cmd) {
}

static void purgeBlockingOverlays(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<UIWindow *> *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *win in windows) {
            NSString *winClass = NSStringFromClass([win class]);
            
            if ([winClass containsString:@"APIClient"] ||
                [winClass containsString:@"ASStatus"] ||
                [winClass containsString:@"Alert"] ||
                win.windowLevel > UIWindowLevelNormal) {
                win.hidden = YES;
                win.alpha = 0.0;
                win.userInteractionEnabled = NO;
            }
            
            for (UIView *sub in [win subviews]) {
                NSString *subClass = NSStringFromClass([sub class]);
                if ([subClass containsString:@"ASStatus"] ||
                    [subClass containsString:@"APIClient"] ||
                    [subClass containsString:@"FCAlert"]) {
                    [sub removeFromSuperview];
                } else {
                    for (UIView *child in [sub subviews]) {
                        if ([child isKindOfClass:[UILabel class]]) {
                            UILabel *lbl = (UILabel *)child;
                            if ([lbl.text containsString:@"Package initializing"] ||
                                [lbl.text containsString:@"Initializing"]) {
                                [sub removeFromSuperview];
                                break;
                            }
                        }
                    }
                }
            }
        }
    });
}

static void hooked_BypassAndDismissUI(id self, SEL _cmd) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isKindOfClass:[UIWindow class]]) {
            UIWindow *win = (UIWindow *)self;
            win.hidden = YES;
            win.alpha = 0.0;
            win.userInteractionEnabled = NO;
        } else if ([self isKindOfClass:[UIView class]]) {
            [(UIView *)self removeFromSuperview];
        } else if ([self isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)self;
            [vc.view removeFromSuperview];
            if (vc.view.window && vc.view.window != [[UIApplication sharedApplication] keyWindow]) {
                vc.view.window.hidden = YES;
                vc.view.window.userInteractionEnabled = NO;
            }
        }

        const char *dismissNames[] = {
            "dismiss",
            "hide",
            "hideLoading",
            "dismissLoading",
            "dismissOverlay",
            "removeOverlay",
            "onLoginSuccess"
        };
        for (size_t i = 0; i < sizeof(dismissNames) / sizeof(dismissNames[0]); i++) {
            SEL dSel = sel_registerName(dismissNames[i]);
            if ([self respondsToSelector:dSel]) {
                ((void (*)(id, SEL))objc_msgSend)(self, dSel);
            }
        }

        purgeBlockingOverlays();
    });
}

static void hookSelectorOnClass(Class cls, SEL sel, IMP newImp) {
    if (!cls || !sel || !newImp) return;

    Method instMethod = class_getInstanceMethod(cls, sel);
    if (instMethod) {
        class_replaceMethod(cls, sel, newImp, method
