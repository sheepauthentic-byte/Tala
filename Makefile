TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++

CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios \
         -I./Dobby/include \
         -I./Dobby/source \
         -I./Dobby/builtin-plugin

# Đã bổ sung -framework WebKit vào liên kết LDFLAGS
LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -framework WebKit -target arm64-apple-ios

DOBBY_SOURCES = \
    Dobby/source/dobby.cpp \
    Dobby/source/MemoryAllocator/BufferBlobAllocator.cc \
    Dobby/source/MemoryAllocator/AssemblyCodeBuffer.cc \
    Dobby/source/InterceptRouting/InterceptRouting.cc \
    Dobby/source/InterceptRouting/common/function-relocation.cc \
    Dobby/source/InterceptRouting/common/trampoline-buffer.cc \
    Dobby/source/InterceptRouting/platform-dependent/intercept_routing_arm64.cc \
    Dobby/source/InstructionRelocator/InstructionRelocator.cc \
    Dobby/source/InstructionRelocator/arm64/InstructionRelocator-arm64.cc \
    Dobby/source/InstructionRelocator/arm64/addr-relocator-arm64.cc \
    Dobby/source/Backend/ARM64/assembler-arm64.cc \
    Dobby/source/Backend/ARM64/compiler-arm64.cc \
    Dobby/source/Backend/ARM64/loader-arm64.cc \
    Dobby/source/Backend/ARM64/interceptor-arm64.cc \
    Dobby/source/Portability/addr_util.cc \
    Dobby/source/Common/logging.cc \
    Dobby/source/Common/assembly_stream.cc \
    Dobby/source/Common/cxx_header_check.cc

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

$(TARGET): build/main.o
	$(CC) $(LDFLAGS) build/main.o $(DOBBY_SOURCES) -o $(TARGET) $(CFLAGS)

clean:
	rm -rf build $(TARGET)
