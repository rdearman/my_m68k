# Toolchain
CFLAGS := -m68000 -g

# Check if running on Windows
ifeq ($(OS),Windows_NT)
    AS = m68k-elf-as.exe
    LD = m68k-elf-ld.exe
    OBJCOPY = m68k-elf-objcopy.exe

    # Define PowerShell commands for Windows
    CREATE_BOOTLOADER_HIGH = powershell -Command "(Get-Content -Path bin/bootloader.bin -Encoding Byte)[1..2] | Set-Content -Path bin/bootloader_high.bin -Encoding Byte"
    CREATE_BOOTLOADER_LOW = powershell -Command "(Get-Content -Path bin/bootloader.bin -Encoding Byte)[0..1] | Set-Content -Path bin/bootloader_low.bin -Encoding Byte"
    RM = powershell -Command "Remove-Item -Recurse -Force"
	MK = powershell -Command "New-Item -ItemType Directory -Path"
else
    AS = m68k-linux-gnu-as
    LD = m68k-linux-gnu-ld
    OBJCOPY = m68k-linux-gnu-objcopy

    # Define dd commands for Unix-based systems
    CREATE_BOOTLOADER_HIGH = dd if=bin/bootloader.bin of=bin/bootloader_high.bin bs=1 skip=1 count=2
    CREATE_BOOTLOADER_LOW = dd if=bin/bootloader.bin of=bin/bootloader_low.bin bs=1 skip=0 count=2
	RM = rm -rf
	MK = mkdir 
    NULLDEV = /dev/null
endif

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

# Conditional Monitor Entry
ifeq ($(QEMU),1)
    QEMU = 1
else
    QEMU = 0
endif


# Linker flags
BOOTLOADER_LD_FLAGS := -Ttext=0x000000

# Rules
.PHONY: all clean bootloader

all: bootloader

bootloader: $(BOOTLOADER_ELF) $(BOOTLOADER_BIN_HIGH) $(BOOTLOADER_BIN_LOW)

# Compile bootloader source
$(BOOTLOADER_OBJ): $(BOOTLOADER_SRC) | $(BUILD_DIR)
	$(AS) -I $(SRC_DIR) --defsym MONITOR_ENTRY=$(MONITOR_ENTRY) --defsym QEMU=$(QEMU) $(CFLAGS)  -o "$@" "$<"

# Compile each common object file in COMMON_SRC
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(AS) -I $(SRC_DIR) --defsym MONITOR_ENTRY=$(MONITOR_ENTRY) --defsym QEMU=$(QEMU) $(CFLAGS) -o "$@" "$<"

# Link the ELF file
$(BOOTLOADER_ELF): $(BOOTLOADER_OBJ) $(COMMON_OBJ) | $(BIN_DIR)
	$(LD) $(BOOTLOADER_LD_FLAGS) -o $@ $^

# Generate the binary files
$(BOOTLOADER_BIN): $(BOOTLOADER_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOTLOADER_BIN_HIGH): $(BOOTLOADER_BIN)
	$(CREATE_BOOTLOADER_HIGH)

$(BOOTLOADER_BIN_LOW): $(BOOTLOADER_BIN)
	$(CREATE_BOOTLOADER_LOW)

#Ensure build and bin directories exist
$(BUILD_DIR):
	$(MK) $(BUILD_DIR)

$(BIN_DIR):
	$(MK) $(BIN_DIR)

clean:
	$(RM) $(BUILD_DIR)
	$(RM) $(BIN_DIR)
	find . -name '*~' -type f -delete
	
nothing:
