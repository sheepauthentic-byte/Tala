CXX = xcrun --sdk iphoneos clang++
SDK_PATH = $(shell xcrun --sdk iphoneos --show-sdk-path)

CXXFLAGS = -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=12.0 -fPIC -x objective-c++ -Idobby/include

# Tách riêng thư viện .a và cờ liên kết đặt ở PHÍA SAU tệp nguồn
LDFLAGS = -shared -lobjc -framework Foundation dobby/build/libdobby.a

all: setup_dobby LibSheepctMod.dylib

setup_dobby:
	@echo "Checking and building Dobby static library..."
	if [ ! -f dobby/build/libdobby.a ]; then \
		mkdir -p dobby/build && \
		cd dobby/build && \
		cmake .. \
			-DCMAKE_SYSTEM_NAME=Darwin \
			-DCMAKE_SYSTEM_PROCESSOR=arm64 \
			-DCMAKE_OSX_SYSROOT=$(SDK_PATH) \
			-DCMAKE_OSX_ARCHITECTURES=arm64 \
			-DCMAKE_C_COMPILER=clang \
			-DCMAKE_CXX_COMPILER=clang++ && \
		make -j$$(sysctl -n hw.ncpu); \
	fi

# Đảm bảo tệp nguồn patch_force_success.mm đứng TRƯỚC, thư viện LDFLAGS (chứa libdobby.a) đứng SAU
LibSheepctMod.dylib: patch_force_success.mm
	$(CXX) $(CXXFLAGS) patch_force_success.mm $(LDFLAGS) -o LibSheepctMod.dylib

clean:
	rm -f LibSheepctMod.dylib
	rm -rf dobby/build
