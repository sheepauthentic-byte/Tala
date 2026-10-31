TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++

# Cờ biên dịch chuẩn, chỉ trỏ vào thư mục include và source cốt lõi
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios \
         -I./Dobby/include \
         -I./Dobby/source \
         -I./Dobby/source/Common \
         -I./Dobby/source/InterceptRouting \
         -I./Dobby/source/InterceptRouting/common \
         -I./Dobby/source/MemoryAllocator \
         -I./Dobby/source/Portability \
         -I./Dobby/source/InstructionRelocator \
         -I./Dobby/source/InstructionRelocator/arm64 \
         -I./Dobby/source/Backend \
         -I./Dobby/source/Backend/ARM64 \
         -I./Dobby/source/base \
         -I./Dobby/source/logging \
         -I./Dobby/third_party/TINYSTL

LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation -target arm64-apple-ios

# CHỈ LẤY CÁC FILE NGUỒN CỐT LÕI VÀ ARM64 CỦA DOBBY (Loại bỏ hoàn toàn x86, x64, elf, plugin rác)
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
