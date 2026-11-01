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

    static void patch_instruction_at(void *target_addr, uint32_t instruction) {
        uintptr_t page_size = getpagesize();
        uintptr_t page_aligned_addr = (uintptr_t)target_addr & ~(page_size - 1);

        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_WRITE | PROT_EXEC);
        memcpy(target_addr, &instruction, 4);
        mprotect((void *)page_aligned_addr, page_size, PROT_READ | PROT_EXEC);
    }

    // Hook hàm kiểm tra key: Bất kể nhập gì, gọi hàm gốc xong ép trả về 1 (Thành công)
    static int (*orig_validateKey)(void *self, SEL _cmd, id inputString) = nullptr;
    static int hooked_validateKey(void *self, SEL _cmd, id inputString) {
        // In ra log để trace nếu cần thiết
        NSLog(@"[SheepctMod] Bypassed key validation for input: %@", inputString);
        if (orig_validateKey) {
            // Vẫn gọi hàm gốc nếu cần duy trì đối tượng, nhưng ép trả về giá trị thành công
            orig_validateKey(self, _cmd, inputString);
        }
        return 1; // 1 = Hợp lệ / Success
    }

    static void apply_universal_bypass(void) {
        uintptr_t base = get_aovnet_base();
        if (!base) return;

        // Vẫn giữ lệnh nop form để không bị kẹt hiển thị
        patch_instruction_at((void *)(base + 0x1dadcc8), 0xD503201F);
        patch_instruction_at((void *)(base + 0x1db0384), 0xD503201F);

        // Hook vào hàm xử lý xác thực bên trong framework (offset validator)
        void *validateFuncAddr = (void *)(base + 0x1dadcc8); 
        DobbyHook(validateFuncAddr, (void *)hooked_validateKey, (void **)&orig_validateKey);
    }

    __attribute__((constructor)) static void init_mod(void) {
        @autoreleasepool {
            apply_universal_bypass();
        }
    }
}
