#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <sys/mman.h>
#include <unistd.h>
#include <cstring>

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

    static void patch_instructions(void *target_addr, const uint32_t *instructions, size_t count) {
        uintptr_t page_size = getpagesize();
        uintptr_t page_aligned_addr = (uintptr_t)target_addr & ~(page_size - 1);

        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_WRITE | PROT_EXEC);
        for (size_t i = 0; i < count; i++) {
            *((uint32_t *)target_addr + i) = instructions[i];
        }
        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_EXEC);
    }

    static void apply_exact_bypass(void) {
        uintptr_t base = get_aovnet_base();
        if (!base) return;

        uint32_t success_return_patch[] = { 0x52800020, 0xD65F03C0 };

        void *loginFormAddr = (void *)(base + 0x1dadcc8);
        patch_instructions(loginFormAddr, success_return_patch, 2);

        void *expiredFormAddr = (void *)(base + 0x1db0384);
        patch_instructions(expiredFormAddr, success_return_patch, 2);
    }

    __attribute__((constructor)) static void init_mod(void) {
        @autoreleasepool {
            apply_exact_bypass();
        }
    }
}
