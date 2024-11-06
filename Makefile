# Toolchain
AS = m68k-linux-gnu-as
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy
CFLAGS := -m68000 -g

# Directories
SRC_DIR := src
BUILD_DIR := build
BIN_DIR := bin

# Source files
BOOTLOADER_SRC := $(SRC_DIR)/bootloader.s
COMMON_SRC := $(SRC_DIR)/spi.s $(SRC_DIR)/uart.s $(SRC_DIR)/i2c.s $(SRC_DIR)/lcd.s $(SRC_DIR)/via.s \
              $(SRC_DIR)/rtc.s $(SRC_DIR)/sd.s $(SRC_DIR)/utils.s

# Object files
COMMON_OBJ := $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.o,$(COMMON_SRC))
BOOTLOADER_OBJ := $(BUILD_DIR)/bootloader.o

# Output binaries
BOOTLOADER_ELF := $(BIN_DIR)/bootloader.elf
BOOTLOADER_BIN := $(BIN_DIR)/bootloader.bin
BOOTLOADER_BIN_HIGH := $(BIN_DIR)/bootloader_high.bin
BOOTLOADER_BIN_LOW := $(BIN_DIR)/bootloader_low.bin

# Conditional Monitor Entry
ifeq ($(WITH_MONITOR),1)
    MONITOR_ENTRY = 0x00400000
else
    MONITOR_ENTRY = _idle_loop
endif

# Linker flags
BOOTLOADER_LD_FLAGS := -Ttext=0x000000

# Rules
.PHONY: all clean bootloader

all: bootloader

bootloader: $(BOOTLOADER_ELF) $(BOOTLOADER_BIN_HIGH) $(BOOTLOADER_BIN_LOW)

# Compile bootloader source
$(BOOTLOADER_OBJ): $(BOOTLOADER_SRC) | $(BUILD_DIR)
	$(AS) --defsym MONITOR_ENTRY=$(MONITOR_ENTRY) $(CFLAGS)  -o "$@" "$<"

# Compile each common object file in COMMON_SRC
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(AS) --defsym MONITOR_ENTRY=$(MONITOR_ENTRY) $(CFLAGS) -o "$@" "$<"

# Link the ELF file
$(BOOTLOADER_ELF): $(BOOTLOADER_OBJ) $(COMMON_OBJ) | $(BIN_DIR)
	$(LD) $(BOOTLOADER_LD_FLAGS) -o $@ $^

# Generate the binary files
$(BOOTLOADER_BIN): $(BOOTLOADER_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOTLOADER_BIN_HIGH): $(BOOTLOADER_BIN)
	dd if=$< of=$@ bs=1 skip=1 count=2

$(BOOTLOADER_BIN_LOW): $(BOOTLOADER_BIN)
	dd if=$< of=$@ bs=1 count=2

# Ensure build and bin directories exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BUILD_DIR)/* $(BIN_DIR)/*
	find . -name '*~' -type f -delete
