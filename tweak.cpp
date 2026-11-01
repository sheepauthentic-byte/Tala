// Language: C++ / Objective-C++
// File: tweek.cpp
// Runtime: iOS / ARM64 / Memory Injection
// Target: aovnet.framework/aovnet

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

    static void write_assembly_patch(void *target_addr) {
        uintptr_t page_size = getpagesize();
        uintptr_t page_aligned_addr = (uintptr_t)target_addr & ~(page_size - 1);

        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_WRITE | PROT_EXEC);

        // Ép thanh ghi trả về giá trị thành công:
        // 1. mov w0, #0x1  (Hex: 20 00 80 D2 -> 0xD2800020)
        // 2. ret            (Hex: C0 03 5D D6 -> 0xD65FC0C0)
        uint32_t patch_instructions[2] = { 0xD2800020, 0xD65FC0C0 };
        
        memcpy(target_addr, patch_instructions, sizeof(patch_instructions));

        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_EXEC);
    }

    static void execute_patch_sequence(void) {
        uintptr_t base = get_aovnet_base();
        if (!base) return;

        // Offset chính xác của showLoginForm trên MAP V1 (0x1dadcc8) hoặc CrackVT (0x1dabee8)
        uintptr_t target_offset = 0x1dadcc8;
        void *target_func = (void *)(base + target_offset);

        write_assembly_patch(target_func);
    }

    __attribute__((constructor)) static void init_patcher(void) {
        @autoreleasepool {
            execute_patch_sequence();
        }
    }
}
