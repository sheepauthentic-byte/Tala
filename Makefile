TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++

CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios \
         -I./Dobby/include \
         -I./Dobby/source \
         -I./Dobby/builtin-plugin \
         -I./Dobby/third_party/TINYSTL

LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -framework WebKit -target arm64-apple-ios

# TỰ ĐỘNG QUÉT TOÀN BỘ FILE NGUỒN C++ THỰC TẾ TRONG THƯ MỤC DOBBY
DOBBY_SOURCES = $(shell find Dobby/source Dobby/builtin-plugin -name "*.cpp" -o -name "*.cc" -o -name "*.c" 2>/dev/null)

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

$(TARGET): build/main.o
	@if [ -z "$(DOBBY_SOURCES)" ]; then \
		echo "LỖI: Không tìm thấy thư mục Dobby hoặc thiếu file nguồn!"; \
		exit 1; \
	fi
	$(CC) $(LDFLAGS) build/main.o $(DOBBY_SOURCES) -o $(TARGET) $(CFLAGS)

clean:
	rm -rf build $(TARGET)
