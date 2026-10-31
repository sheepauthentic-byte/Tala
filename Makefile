# --- CẤU HÌNH BIÊN DỊCH ---
TARGET = libSheepctMod.dylib
CC = clang
CXX = clang++

SRC_DIR = .
BUILD_DIR = build

# Tự động quét tất cả các file nguồn trong thư mục
SOURCES = $(wildcard $(SRC_DIR)/*.m) $(wildcard $(SRC_DIR)/*.mm) $(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/*.c)
OBJECTS = $(patsubst $(SRC_DIR)/%.m, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.mm, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SOURCES)))))

# Cờ biên dịch tối ưu hóa
CFLAGS = -fobjc-arc -O3 -Wall -fPIC
CXXFLAGS = -std=c++11 -O3 -Wall -fPIC

# Cờ liên kết framework giao diện iOS
LDFLAGS = -dynamiclib -undefined dynamic_lookup \
          -framework Foundation \
          -framework UIKit \
          -framework CoreGraphics \
          -framework QuartzCore

# --- LUỒNG THỰC THI CHÍNH ---
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
	@echo "=========================================="
	@echo " Biên dịch thành công tệp: $(TARGET)"
	@echo "=========================================="

# Dọn dẹp tệp tạm và tệp build
clean:
	rm -rf $(BUILD_DIR) $(TARGET)
	@echo "Đã dọn dẹp sạch sẽ các tệp biên dịch cũ!"

.PHONY: all clean
