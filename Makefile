# Tên file đầu ra (không có đuôi .dylib)
TARGET = MyBypassTweak

# Đặt đúng tên file .m của bạn ở đây
SRC = tweak.m

# Các Framework cần thiết cho iOS
FRAMEWORKS = -framework Foundation -framework UIKit

# Cờ biên dịch (Compile Flags)
CFLAGS = -dynamiclib -arch arm64 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -miphoneos-version-min=12.0

all: $(TARGET).dylib

$(TARGET).dylib: $(SRC)
	@echo "Đang biên dịch $(TARGET).dylib từ $(SRC)..."
	clang $(CFLAGS) $(FRAMEWORKS) $(SRC) -o $(TARGET).dylib
	@echo "Biên dịch thành công!"

clean:
	@echo "Đang dọn dẹp file cũ..."
	rm -f $(TARGET).dylib

.PHONY: all clean
