#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <sys/mman.h>
#include <unistd.h>
#include <cstring>
#include "dobby.h"

#define FINAL_LOG(fmt, ...) NSLog(@"[Sheepct-AOV-Final] " fmt, ##__VA_ARGS__)

extern "C" {
    static uintptr_t get_framework_base(void) {
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
        FINAL_LOG("Intercepted _apiclient_paid. Forcing authorization success (1).");
        return 1;
    }

    static void execute_final_patch(void) {
        uintptr_t base = get_framework_base();
        if (!base) {
            FINAL_LOG("Error: Target aovnet framework base address not found.");
            return;
        }

        void *targetAddr = (void *)(base + 0xc5d628);
        FINAL_LOG("Target hook address resolved at: %p", targetAddr);

        int status = DobbyHook(targetAddr, (void *)hooked_apiclient_paid, (void **)&orig_apiclient_paid);
        if (status == 0) {
            FINAL_LOG("DobbyHook successfully established for map v1.");
        } else {
            FINAL_LOG("DobbyHook failed with status code: %d", status);
        }
    }

    __attribute__((constructor)) static void sheepct_final_entry(void) {
        @autoreleasepool {
            FINAL_LOG("Initializing Sheepct Final Patch Module...");
            execute_final_patch();
        }
    }
}
