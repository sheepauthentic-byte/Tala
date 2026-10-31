TARGET = libSheepctMod.dylib
CC = xcrun --sdk iphoneos clang++
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios -I./Dobby/include
LDFLAGS = -dynamiclib -install_name @executable_path/libSheepctMod.dylib -framework UIKit -framework Foundation

all: $(TARGET)

build/main.o: main.mm
	mkdir -p build
	$(CC) $(CFLAGS) -c main.mm -o build/main.o

# Biên dịch mã nguồn Dobby cùng với main.o để tạo tệp dylib hoàn chỉnh
$(TARGET): build/main.o
	# Biên dịch các tệp nguồn cơ bản của Dobby hoặc liên kết trực tiếp
	cd Dobby && cmake -B build -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 && cmake --build build
	$(CC) $(LDFLAGS) build/main.o Dobby/build/libdobby.a -o $(TARGET)

clean:
	rm -rf build $(TARGET)
	rm -rf Dobby/build
