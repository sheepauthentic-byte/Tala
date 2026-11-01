# Định nghĩa trình biên dịch và cờ tối ưu cho iOS ARM64
CXX = xcrun --sdk iphoneos clang++
SDK_PATH = $(shell xcrun --sdk iphoneos --show-sdk-path)

CXXFLAGS = -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=12.0 -fPIC -Idobby/include
LDFLAGS = -shared -lobjc -framework Foundation dobby/build/libdobby.a

all: setup_dobby LibSheepctMod.dylib

setup_dobby:
setup_dobby:
	@echo "Building Dobby static library via CMake for iOS ARM64..."
	mkdir -p dobby/build
	cd dobby/build && cmake .. \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_SYSTEM_PROCESSOR=arm64 \
		-DCMAKE_OSX_SYSROOT=$(SDK_PATH) \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_C_COMPILER=clang \
		-DCMAKE_CXX_COMPILER=clang++
	cd dobby/build && make -j$(sysctl -n hw.ncpu)

LibSheepctMod.dylib: patch_force_success.cpp
	$(CXX) $(CXXFLAGS) patch_force_success.cpp $(LDFLAGS) -o LibSheepctMod.dylib

clean:
	rm -f LibSheepctMod.dylib
	rm -rf dobby/build
