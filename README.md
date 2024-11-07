
# Motorola 68000 Homebrew Computer Project

Welcome to the **My Motorola 68000 Homebrew Computer Project** repository! This project is a personal endeavour to build a fully custom computer from the ground up using the Motorola 68000 CPU, alongside a range of memory and I/O components. This repository contains all source code, schematics, and documentation to help you understand and replicate this classic hardware-based build.

## 📜 Project Overview

The goal of this project is to create a working computer around the Motorola 68000 processor, featuring:

- A custom **bootloader** and **Power-On Self Test (POST)** for hardware validation.
- **Custom OS** development with support for a variety of vintage applications.
- Complete **I/O handling** through UART, SPI, and I2C, with a focus on optimised device control.
- **Memory management** and **address decoding** to fully utilise 4MB ROM and 4MB RAM.
- Support for classic peripherals, including **MOD-VGA** for video output, SD card storage, and LCD display.


## 🎯 Features

- **Assembly Bootloader**: Initialises hardware and performs POST checks.
- **Custom OS and Monitor Program**: Basic OS functionality with a WozMon-style monitor for low-level control.
- **Peripheral Integration**: Handles UART communication, LCD output, SPI and I2C devices.
- **Interrupt Handling**: Configured to manage multiple peripherals through hardware interrupts.
- **I/O Libraries**: Developed in assembly for efficient control over UART, SPI, and I2C.

## 🛠️ Hardware Components

Key components in the build include:

- **Motorola 68000 CPU** (TS68000CP8)
- **W65C22N6TPG VIA**: General I/O, SPI, and I2C handling.
- **M82C51A UART**: For serial communication with RS-232 support.
- **SST39SF040 and AS6C4008-55PCN**: ROM and RAM, respectively, for memory storage.
- **MOD-VGA**: Video output over VGA.
- **Various Decoders, AND Gates, and Custom Reset Circuitry**

For the complete pinout and wiring details, please refer to [Pinout.md](Pinout.md) (TBD) in this repository.

## 📂 Repository Structure

```plaintext

.
├── LICENSE
├── Makefile           # Build file to compile and link assembly code
└── README.md          # Project README
├── bin
├── build
├── linker.ld
└── src                # Source code for the project in assembly language
    ├── bootloader.s   # Bootloader source code & POST
    ├── fat.s          # FAT32 file system (eventually)
    ├── i2c.s          # Comms with i2c devices 
    ├── interrupts.s   # Interrupt handler
    ├── lcd.s          # LCD Screen library
    ├── main.s         # Monitor Program
    ├── memory_alloc.s # malloc / free
    ├── monitor_io.s   # IO for Monitor program
    ├── rtc.s          # Real Time Clock library
    ├── sd.s           # SD card file IO
    ├── spi.s          # Cooms with SPI devices
    ├── uart.s         # UART library
    ├── utils.s        # Misc Utils
    └── via.s          # comms to via chip

```

## 🚀 Getting Started

To get started with this project, follow these steps:

### Prerequisites

- **Cross-compiler for Motorola 68000**: Use the GCC toolchain for M68K.
- **GNU Make**: To handle the build process.
- **Soldering and Perfboard Assembly**: Required for the hardware build.

### Setup and Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/rdearman/my_m68k.git
   cd my_m68k
   ```

2. **Build the source code**:
   ```bash
   make all
   ```

3. **Load the bootloader and OS** to the ROM chips:
   - For detailed steps on flashing the ROM, refer to the [Setup Guide](docs/Setup.md). (TBD)

4. **To use with emulator instead**:
   ```bash
   qemu-system-m68k -M virt -m 8M -kernel bin/bootloader.elf -serial stdio -s -S 
   ```

### Running the System

- **Power on the system** with the ROM and RAM installed.
- The bootloader will perform a POST, followed by OS initialisation.

## 🔍 Key Files and Code Organisation

| File                | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `bootloader.s`      | Initialises hardware, performs POST, and transitions to the OS.             |
| `uart.s`            | UART communication routines.                                                |
| `spi.s`             | SPI control and data transfer functions.                                    |
| `i2c.s`             | I2C control functions for connected peripherals.                            |
| `interrupts.s`      | Sets up interrupt vectors and handles multiple peripheral interrupts.       |
| `Makefile`          | Automates the build process for all source files.                           |
| `utils.s`           | Contains error reporting and debug utilities.                               |

## 📚 Documentation

For more in-depth information, check out the following:

- **[Pinout.md](docs/Pinout.md)**: Pin configurations for each device. (TBD)
- **[Schematics](docs/Schematics)**: Circuit schematics for hardware setup. (TDB)
- **[Setup Guide](docs/Setup.md)**: Step-by-step instructions to build and initialise the system. (TBD)

## 🛠️ Development Notes

- **Assembly Style**: Follows GNU assembly conventions with `/* ... */` comments for documentation.
- **Memory Map**: ROM is mapped to 0x000000, RAM to MMIO starting at 0x100000.
- **Interrupt Handling**: Configured for efficient peripheral management via memory-mapped I/O.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributions

I'm not really taking contributions because this is mainly a learning exercise for me. But happy to listen to new ideas, or suggestions. 

---

Enjoy diving into the world of retro computing with the Motorola 68000!

## Memory Map

This section defines the memory layout for the Motorola 68000 homebrew computer project, detailing the locations of RAM, ROM, stack, and memory-mapped I/O devices.

| Multiplexer Output | Address Range / Device            | Description                                      |
|--------------------|-----------------------------------|--------------------------------------------------|
| `Y1 (0x10000000)`        | D43256C (RAM)                    | Lower RAM device                                 |
| `Y2 (0x20000000)`        | W65C22N6TPG (VIA Chip) CS1       | First chip select for VIA                        |
| `Y3 (0x20000000)`        | W65C22N6TPG (VIA Chip) CS2       | Second chip select for VIA                       |
| `Y4 (0x40000000)`        | M82C51A (UART) WR                | Write line for UART                              |
| `Y5 (0x50000000)`        | M82C51A (UART) RD                | Read line for UART                               |
| `Y6 (0x60000000)`        | CD74HCT245P (Data Bus Transceiver) | Controls data flow direction                     |

| Address Range        | Description                        |
|----------------------|------------------------------------|
| `0x00000000` - `0x000FFFFF` | **ROM** - Bootloader, OS, and monitor program |
| `0x00100000` - `0x001FFFFF` | **RAM** - General-purpose RAM for program data |
| `0x00200000`               | **Stack Top** - Top of the stack |
| `0xC00000`                 | **UART Base** - M82C51A memory-mapped address |
| `0xC00020`                 | **SPI Base** - SPI peripheral interface |
| `0xC00040`                 | **I2C Base** - I2C peripheral interface |
| `Y1 - Y6`                  | **GPIO and Chip Selects** - Managed by MM74HC154N |

### Notes
- **ROM** holds the bootloader, OS, and monitor programs, occupying the first 1MB.
- **RAM** is in the next 1MB for general program data.
- **Stack Top** is located at `0x200000`.
- **VIA Chip**: Accessed via CS1 and CS2 lines, allowing for multiple chip select options for expanded I/O capabilities.
- **UART (M82C51A)**: Separate read (`Y5`) and write (`Y4`) lines for controlled data access.
- **Data Bus Transceiver (CD74HCT245P)**: Controlled via `Y6` to manage data direction between the CPU and peripherals.

This detailed map provides a clear structure of memory addresses and device-specific mappings, critical for understanding address space and device handling.
