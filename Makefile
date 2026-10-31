TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++

# Thêm đầy đủ các đường dẫn include của Dobby để trình biên dịch không bao giờ bị thiếu file header
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios \
         -I./Dobby/include \
         -I./Dobby/source \
         -I./Dobby/source/Common \
         -I./Dobby/source/InterceptRouting \
         -I./Dobby/source/InterceptRouting/common \
         -I./Dobby/source/MemoryAllocator \
         -I./Dobby/source/Portability \
         -I./Dobby/source/InstructionRelocator \
         -I./Dobby/source/InstructionRelocator/arm64 \
         -I./Dobby/source/Backend \
         -I./Dobby/source/Backend/ARM64

LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -target arm64-apple-ios

# Tìm tất cả các file mã nguồn C/CPP trong Dobby
DOBBY_SOURCES = $(shell find Dobby/source -name "*.cpp" -o -name "*.c" -o -name "*.cc")

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

$(TARGET): build/main.o
	$(CC) $(LDFLAGS) build/main.o $(DOBBY_SOURCES) -o $(TARGET) $(CFLAGS)

clean:
	rm -rf build $(TARGET)
