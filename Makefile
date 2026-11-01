# Khai báo trình biên dịch riêng, cờ kiến trúc đưa vào CXXFLAGS
CXX = xcrun --sdk iphoneos clang++
SDK_PATH = $(shell xcrun --sdk iphoneos --show-sdk-path)

# Cờ biên dịch tối ưu cho iOS ARM64 (đảm bảo -arch arm64 đứng độc lập)
CXXFLAGS = -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=12.0 -fPIC -x objective-c++ \
           -Idobby/include \
           -Idobby/source \
           -Idobby/source/Backend \
           -Idobby/source/Backend/Arm64

# Danh sách các tệp mã nguồn C++ cốt lõi của Dobby
DOBBY_SRCS = dobby/source/InterceptRouting/InterceptRouting.cc \
             dobby/source/InterceptRouting/AssemblyRouting/arm64/routing-arm64.cc \
             dobby/source/MemoryAllocator/CodeBuffer/MemoryCodeBuffer.cc \
             dobby/source/MemoryAllocator/AssemblyCodePatch.cc \
             dobby/source/CoreServices/MemoryAllocator.cc \
             dobby/source/CoreServices/MachMemory.cc \
             dobby/builtin/SymbolResolver/macho/SymbolResolver.cc

LDFLAGS = -shared -lobjc -framework Foundation

all: clone_dobby LibSheepctMod.dylib

clone_dobby:
	@if [ ! -d "dobby" ]; then \
		echo "Cloning Dobby repository..."; \
		git clone --depth=1 https://github.com/jmpews/Dobby.git dobby; \
	fi

LibSheepctMod.dylib: patch_force_success.mm clone_dobby
	@echo "Compiling and linking LibSheepctMod.dylib for arm64..."
	$(CXX) $(CXXFLAGS) patch_force_success.mm $(DOBBY_SRCS) $(LDFLAGS) -o LibSheepctMod.dylib
	@if [ -f LibSheepctMod.dylib ]; then \
		echo "SUCCESS: LibSheepctMod.dylib built successfully!"; \
	else \
		echo "ERROR: Build failed."; \
		exit 1; \
	fi

clean:
	rm -f LibSheepctMod.dylib
	rm -rf dobby
