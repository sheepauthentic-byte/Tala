# Language: Makefile
# File: Makefile
# Runtime: iOS / ARM64 / clang++ (ObjC++)

TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++
SDKROOT = $(shell xcrun --sdk iphoneos --show-sdk-path)
CFLAGS = -dynamiclib -arch arm64 -O3 -std=c++17 -F$(SDKROOT)/System/Library/Frameworks -isysroot $(SDKROOT) -miphoneos-version-min=12.0 -x objective-c++
LDFLAGS = -lobjc -framework Foundation

all: $(TARGET)

$(TARGET): patch_force_success.cpp
	$(CC) $(CFLAGS) patch_force_success.cpp -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET)
