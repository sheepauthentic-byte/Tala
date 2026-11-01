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

    static void patch_instruction_at(void *target_addr, uint32_t instruction) {
        uintptr_t page_size = getpagesize();
        uintptr_t page_aligned_addr = (uintptr_t)target_addr & ~(page_size - 1);

        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_WRITE | PROT_EXEC);
        memcpy(target_addr, &instruction, 4);
        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_EXEC);
    }

    static void apply_menu_safe_patches(void) {
        uintptr_t base = get_aovnet_base();
        if (!base) return;

        void *loginFormAddr = (void *)(base + 0x1dadcc8);
        patch_instruction_at(loginFormAddr, 0xD503201F);

        void *expiredFormAddr = (void *)(base + 0x1db0384);
        patch_instruction_at(expiredFormAddr, 0xD503201F);
    }

    __attribute__((constructor)) static void init_mod(void) {
        @autoreleasepool {
            apply_menu_safe_patches();
        }
    }
}
