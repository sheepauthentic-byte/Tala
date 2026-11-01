#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <sys/mman.h>
#include <unistd.h>
#include <cstring>
#include "dobby.h"

extern "C" {
    static uintptr_t get_aovnet_base(void) {
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; i++) {
            const char *name = _dyld_get_image_name(i);
            if (name && strstr(name, "aovnet.framework/aovnet") != NULL) {
                return (uintptr_t)_dyld_get_image_header(i);
            }
        }
        return 0;
    }

    static int (*orig_apiclient_paid)(void *self, SEL _cmd) = nullptr;
    static int hooked_apiclient_paid(void *self, SEL _cmd) {
        if (orig_apiclient_paid) {
            orig_apiclient_paid(self, _cmd);
        }
        return 1;
    }

    static void apply_mapv1_bypass(void) {
        uintptr_t base = get_aovnet_base();
        if (!base) return;

        void *paidFuncAddr = (void *)(base + 0xc5d628);
        DobbyHook(paidFuncAddr, (void *)hooked_apiclient_paid, (void **)&orig_apiclient_paid);
    }

    __attribute__((constructor)) static void init_mod(void) {
        @autoreleasepool {
            apply_mapv1_bypass();
        }
    }
}
