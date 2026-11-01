# Định nghĩa trình biên dịch và cờ tối ưu cho iOS ARM64
CXX = xcrun --sdk iphoneos clang++
SDK_PATH = $(shell xcrun --sdk iphoneos --show-sdk-path)

# Thêm đường dẫn -I để trình biên dịch tìm thấy dobby.h trong thư mục dobby vừa clone
CXXFLAGS = -arch arm64 -isysroot $(SDK_PATH) -miphoneos-version-min=12.0 -fPIC -Idobby/include -Idobby/source

# Biên dịch trực tiếp mã nguồn Dobby cùng với tệp patch của bạn để tránh lỗi thiếu thư viện tĩnh (libdobby.a)
SRCS = patch_force_success.cpp \
       dobby/source/InterceptRouting/AssemblyRouting/arm64/routing-arm64.cc \
       dobby/source/InterceptRouting/InterceptRouting.cc \
       dobby/source/MemoryAllocator/CodeBuffer/MemoryCodeBuffer.cc \
       dobby/source/MemoryAllocator/AssemblyCodePatch.cc \
       dobby/source/CoreServices/MemoryAllocator.cc \
       dobby/source/CoreServices/MachMemory.cc \
       dobby/builtin/SymbolResolver/macho/SymbolResolver.cc

LDFLAGS = -shared -lobjc -framework Foundation

libSheepctMod.dylib: $(SRCS)
	$(CXX) $(CXXFLAGS) $(SRCS) $(LDFLAGS) -o LibSheepctMod.dylib

clean:
	rm -f LibSheepctMod.dylib
