TARGET = libSheepctMod.dylib

# Sử dụng xcrun để trỏ trực tiếp vào iPhoneOS SDK của Xcode
SDK = iphoneos
CC = xcrun --sdk $(SDK) clang
CXX = xcrun --sdk $(SDK) clang++

SRC_DIR = .
BUILD_DIR = build

SOURCES = $(wildcard $(SRC_DIR)/*.m) $(wildcard $(SRC_DIR)/*.mm) $(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/*.c)
OBJECTS = $(patsubst $(SRC_DIR)/%.m, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.mm, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SOURCES)))))

# Bắt buộc phải có -target arm64-apple-ios để nhận diện UIKit của iOS
CFLAGS = -fobjc-arc -O3 -Wall -fPIC -target arm64-apple-ios
CXXFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios

LDFLAGS = -dynamiclib -undefined dynamic_lookup \
          -framework Foundation \
          -framework UIKit \
          -framework CoreGraphics \
          -framework QuartzCore

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.m
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.mm
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJECTS)
	$(CXX) $(LDFLAGS) -o $@ $^
	@echo "Bien dịch thanh cong cho iOS: $(TARGET)"

clean:
	rm -rf $(BUILD_DIR) $(TARGET)
CFLAGS = -std=c++11 -O3 -Wall -fPIC -target arm64-apple-ios -I./Dobby/include

build/main.o: main.mm
	mkdir -p build
	xcrun --sdk iphoneos clang++ $(CFLAGS) -c main.mm -o build/main.o

.PHONY: all clean
