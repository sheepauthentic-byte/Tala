TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios -I./Dobby/include
LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -target arm64-apple-ios

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

# Bắt buộc CMake tự sinh cấu hình và build Dobby thành thư viện tĩnh libdobby.a chuẩn iOS
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
	cd Dobby/build && make -j$$(sysctl -n hw.ncpu)

# Link file main.o với libdobby.a để tạo dylib hoàn chỉnh
$(TARGET): build/main.o Dobby/build/libdobby.a
	$(CC) $(LDFLAGS) build/main.o Dobby/build/libdobby.a -o $(TARGET)

clean:
	rm -rf build $(TARGET)
	rm -rf Dobby/build
