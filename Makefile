TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios -I./Dobby/include -I./Dobby/source
LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -target arm64-apple-ios

# Tự động tìm tất cả file nguồn C/CPP trong thư mục Dobby
DOBBY_SOURCES = $(shell find Dobby/source -name "*.cpp" -o -name "*.c" -o -name "*.cc")

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

$(TARGET): build/main.o
	$(CC) $(LDFLAGS) build/main.o $(DOBBY_SOURCES) -o $(TARGET) $(CFLAGS)

clean:
	rm -rf build $(TARGET)
