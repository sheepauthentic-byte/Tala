TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios -I./Dobby/include
LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -target arm64-apple-ios

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

# Tự động cấu hình và build Dobby bằng CMake với thiết lập chuẩn iOS
Dobby/build/libdobby.a:
	rm -rf Dobby/build
	mkdir -p Dobby/build
	cd Dobby/build && cmake .. \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_OSX_SYSROOT=iphoneos \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_C_COMPILER="$$(xcrun --sdk iphoneos -find clang)" \
		-DCMAKE_CXX_COMPILER="$$(xcrun --sdk iphoneos -find clang++)"

$(TARGET): build/main.o Dobby/build/libdobby.a
	# Nếu CMake không build ra file .a tĩnh tự động, dùng lệnh gom toàn bộ object file của Dobby
	$(CC) $(LDFLAGS) build/main.o $$(find Dobby/build -name "*.o" -o -name "*.a") -o $(TARGET) $(CFLAGS)

clean:
	rm -rf build $(TARGET)
	rm -rf Dobby/build
