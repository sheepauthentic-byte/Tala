# Language: Makefile
# File: Makefile
# Runtime: iOS / ARM64 / clang++

TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++
CFLAGS = -dynamiclib -arch arm64 -O3 -std=c++17 -F$(SDKROOT)/System/Library/Frameworks -miphoneos-version-min=12.0
LDFLAGS = -lobjc -framework Foundation

all: $(TARGET)

$(TARGET): tweek.cpp
	$(CC) $(CFLAGS) tweek.cpp -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET)
