# ==========================================
# Makefile biên dịch iOS Dynamic Library (.dylib)
# Tác giả: TRẦN MẠNH CƯỜNG (Project: sheepct)
# ==========================================

TARGET = libSheepctMod.dylib
CC = clang
CXX = clang++

SRC_DIR = .
BUILD_DIR = build

SOURCES = $(wildcard $(SRC_DIR)/*.m) $(wildcard $(SRC_DIR)/*.mm) $(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/*.c)
OBJECTS = $(patsubst $(SRC_DIR)/%.m, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.mm, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, \
          $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SOURCES)))))

CFLAGS = -fobjc-arc -O3 -Wall -fPIC
CXXFLAGS = -std=c++11 -O3 -Wall -fPIC
LDFLAGS = -dynamiclib -undefined dynamic_lookup -framework Foundation -framework UIKit -framework CoreGraphics -framework QuartzCore

all: $(BUILD_DIR) $(BUILD_DIR)/$(TARGET)

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

$(BUILD_DIR)/$(TARGET): $(OBJECTS)
	$(CXX) $(LDFLAGS) -o $@ $^
	@echo ""
	@echo " Biên dịch thành công thư viện: $(TARGET)"
	@echo " Bản quyền: sheepct (TRẦN MẠNH CƯỜNG)"
	@echo ""

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

.PHONY: all clean
