CXX = xcrun --sdk iphoneos clang++
SDK_PATH = $(shell xcrun --sdk iphoneos --show-sdk-path)

CXXFLAGS = -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=12.0 -fPIC -x objective-c++ -Idobby/include

all: setup_dobby LibSheepctMod.dylib

setup_dobby:
	@if [ ! -d "dobby" ]; then \
		echo "Cloning Dobby repository..."; \
		git clone --depth=1 https://github.com/jmpews/Dobby.git dobby; \
	fi
	@if [ ! -f "dobby/build/libdobby.a" ] && [ ! -f "dobby/build/lib/libdobby.a" ]; then \
		echo "Configuring and building Dobby via CMake..."; \
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

# Tự động quét tìm libdobby.a dù nó nằm ở bất kỳ thư mục con nào trong build/
DOBBY_LIB = $(shell find dobby/build -name "libdobby.a" | head -n 1)

patch_force_success.o: patch_force_success.mm
	$(CXX) $(CXXFLAGS) -c patch_force_success.mm -o patch_force_success.o

LibSheepctMod.dylib: patch_force_success.o setup_dobby
	@echo "Linking with Dobby library at: $(DOBBY_LIB)"
	$(CXX) -arch arm64 -isysroot $(SDK_PATH) -dynamiclib \
		patch_force_success.o \
		$(DOBBY_LIB) \
		-lobjc -framework Foundation \
		-o LibSheepctMod.dylib
	@if [ -f LibSheepctMod.dylib ]; then \
		echo "SUCCESS: LibSheepctMod.dylib built successfully!"; \
	else \
		echo "ERROR: Build failed."; \
		exit 1; \
	fi

clean:
	rm -f LibSheepctMod.dylib patch_force_success.o
	rm -rf dobby
