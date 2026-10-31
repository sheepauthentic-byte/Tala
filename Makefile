TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++

CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios \
         -I./Dobby/include \
         -I./Dobby/source \
         -I./Dobby/builtin-plugin \
         -I./Dobby/third_party/TINYSTL

LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -target arm64-apple-ios

# Dò tìm tự động toàn bộ file .cpp và .cc thực tế bên trong thư mục Dobby/source
# Nếu thư mục không tồn tại hoặc trống, nó sẽ không làm sập make mà tự lọc sạch
DOBBY_SOURCES = $(shell find Dobby/source -name "*.cpp" -o -name "*.cc" 2>/dev/null)

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

$(TARGET): build/main.o
	@if [ -z "$(DOBBY_SOURCES)" ]; then \
		echo "LỖI: Không tìm thấy source code Dobby trong thư mục Dobby/source!"; \
		exit 1; \
	fi
	$(CC) $(LDFLAGS) build/main.o $(DOBBY_SOURCES) -o $(TARGET) $(CFLAGS)

clean:
	rm -rf build $(TARGET)
