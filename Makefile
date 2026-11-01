CXX = xcrun --sdk iphoneos clang++
SDK_PATH = $(shell xcrun --sdk iphoneos --show-sdk-path)

CXXFLAGS = -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=12.0 -fPIC -x objective-c++ -Idobby/include

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

# Bước 1: Chỉ biên dịch tệp .mm thành tệp đối tượng .o (Không dính dáng gì đến libdobby.a ở đây)
patch_force_success.o: patch_force_success.mm
	$(CXX) $(CXXFLAGS) -c patch_force_success.mm -o patch_force_success.o

# Bước 2: Liên kết tệp đối tượng .o với thư viện tĩnh libdobby.a để tạo ra dylib chuẩn
LibSheepctMod.dylib: patch_force_success.o
	$(CXX) -arch arm64 -isysroot $(SDK_PATH) -dynamiclib \
		patch_force_success.o \
		dobby/build/libdobby.a \
		-lobjc -framework Foundation \
		-o LibSheepctMod.dylib

clean:
	rm -f LibSheepctMod.dylib patch_force_success.o
	rm -rf dobby/build
