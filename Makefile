# libSheepctMod.dylib - iOS arm64
# Chi sua Makefile nay. main.mm giu nguyen, khong sua.
#
# Ly do sua: Dobby khong the build bang cach glob tat ca file .cc/.cpp/.c
# trong Dobby/source + Dobby/builtin-plugin roi nem thang vao lenh link:
#  - Dobby yeu cau C++17, Makefile cu dung -std=c++11.
#  - Glob lay ca file x86/x64/arm (27/85 file) va ca plugin Android/ELF/PE,
#    test, khong phai arm64/iOS.
#  - Thieu file .asm trampoline arm64 nen link se thieu symbol.
#  - Thieu include cua Dobby (external/logging, source, ...) va define
#    cua CMake; -I./Dobby/third_party/TINYSTL khong ton tai.
# Cach dung: build Dobby bang chinh CMake cua no (nhu scripts/platform_builder.py
# cua Dobby: -DCMAKE_SYSTEM_NAME=iOS, arm64, sysroot iphoneos), lay libdobby.a,
# roi moi link voi main.o. Workflow hien tai chi can chay `make clean && make`.

TARGET := libSheepctMod.dylib

SDK_PATH := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
CC := xcrun --sdk iphoneos clang++

IPHONEOS_MIN := 14.0
ARCH := arm64

# 2026-10-31: main.mm dung _dyld_get_image_header() nhung khong #include
# <mach-o/dyld.h>; Makefile khong sua main.mm nen dung -include de nap
# header nay cho moi lan bien dich main.mm (chi sua phia Makefile).
MAIN_CXXFLAGS := -std=c++17 -O3 -Wall -fPIC -fobjc-arc \
	-arch $(ARCH) -miphoneos-version-min=$(IPHONEOS_MIN) \
	-isysroot $(SDK_PATH) \
	-I./Dobby/include \
	-include <mach-o/dyld.h>

MAIN_LDFLAGS := -dynamiclib \
	-arch $(ARCH) -miphoneos-version-min=$(IPHONEOS_MIN) \
	-isysroot $(SDK_PATH) \
	-install_name @executable_path/$(TARGET) \
	-framework UIKit -framework Foundation -framework WebKit -framework CoreGraphics

DOBBY_DIR := Dobby
DOBBY_BUILD_DIR := build/dobby-iphoneos-arm64
DOBBY_LIB := $(DOBBY_BUILD_DIR)/libdobby.a

.PHONY: all clean check-sdk
all: check-sdk $(TARGET)

check-sdk:
	@if [ -z "$(SDK_PATH)" ]; then echo "LOI: khong tim thay iPhoneOS SDK (xcrun --sdk iphoneos --show-sdk-path)"; exit 1; fi

build/main.o: main.mm
	mkdir -p build
	$(CC) $(MAIN_CXXFLAGS) -c main.mm -o $@

$(DOBBY_LIB): $(DOBBY_DIR)/CMakeLists.txt
	@if [ ! -d "$(DOBBY_DIR)" ]; then echo "LOI: khong co thu muc Dobby/ - workflow phai clone Dobby truoc khi chay make"; exit 1; fi
	cmake -S $(DOBBY_DIR) -B $(DOBBY_BUILD_DIR) \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_SYSTEM_PROCESSOR=arm64 \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_OSX_SYSROOT="$(SDK_PATH)" \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=$(IPHONEOS_MIN) \
		-DCMAKE_BUILD_TYPE=Release \
		-DDOBBY_BUILD_EXAMPLE=OFF \
		-DDOBBY_BUILD_TEST=OFF
	cmake --build $(DOBBY_BUILD_DIR) --target dobby_static -- -j4
	@test -f $@ || { echo "LOI: khong tao duoc $@"; exit 1; }

$(TARGET): build/main.o $(DOBBY_LIB)
	$(CC) $(MAIN_LDFLAGS) build/main.o $(DOBBY_LIB) -o $@

clean:
	rm -rf build $(TARGET)

