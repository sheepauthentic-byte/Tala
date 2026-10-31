TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios -I./Dobby/include
LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -target arm64-apple-ios

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

# Truyền đầy đủ CMAKE_SYSTEM_PROCESSOR để vượt qua build_environment_check.cmake của Dobby
Dobby/build/libdobby.a:
	rm -rf Dobby/build
	mkdir -p Dobby/build
	cd Dobby/build && cmake .. \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_SYSTEM_PROCESSOR=arm64 \
		-DCMAKE_APPLE_SILICON_PROCESSOR=arm64 \
		-DCMAKE_OSX_SYSROOT=iphoneos \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_C_COMPILER="$$(xcrun --sdk iphoneos -find clang)" \
		-DCMAKE_CXX_COMPILER="$$(xcrun --sdk iphoneos -find clang++)"
	cd Dobby/build && make -j$$(sysctl -n hw.ncpu)

$(TARGET): build/main.o Dobby/build/libdobby.a
	$(CC) $(LDFLAGS) build/main.o Dobby/build/libdobby.a -o $(TARGET)

clean:
	rm -rf build $(TARGET)
	rm -rf Dobby/build
