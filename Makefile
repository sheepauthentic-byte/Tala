CXX = xcrun --sdk iphoneos clang++
SDK_PATH = $(shell xcrun --sdk iphoneos --show-sdk-path)

CXXFLAGS = -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=12.0 -fPIC -x objective-c++ -Idobby/include

# Kiểm tra xem libdobby.a nằm ở đâu để tự động trỏ đúng đường dẫn
DOBBY_LIB = $(wildcard dobby/build/libdobby.a)
ifeq ($(strip $(DOBBY_LIB)),)
    DOBBY_LIB = $(wildcard dobby/build/*/libdobby.a)
endif

all: setup_dobby LibSheepctMod.dylib

setup_dobby:
	@echo "Checking and building Dobby static library..."
	if [ ! -f "dobby/build/libdobby.a" ] && [ ! -f "dobby/build/lib/libdobby.a" ]; then \
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

patch_force_success.o: patch_force_success.mm
	$(CXX) $(CXXFLAGS) -c patch_force_success.mm -o patch_force_success.o

LibSheepctMod.dylib: patch_force_success.o
	@echo "Locating libdobby.a..."
	@echo "Found lib at: $(DOBBY_LIB)"
	$(CXX) -arch arm64 -isysroot $(SDK_PATH) -dynamiclib \
		patch_force_success.o \
		$(DOBBY_LIB) \
		-lobjc -framework Foundation \
		-o LibSheepctMod.dylib
	@if [ -f LibSheepctMod.dylib ]; then \
		echo "SUCCESS: LibSheepctMod.dylib created successfully!"; \
	else \
		echo "ERROR: Failed to create LibSheepctMod.dylib"; \
		exit 1; \
	fi

clean:
	rm -f LibSheepctMod.dylib patch_force_success.o
	rm -rf dobby/build
