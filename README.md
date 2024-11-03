
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
   git clone https://github.com/username/68000-homebrew-computer.git
   cd 68000-homebrew-computer
   ```

2. **Build the source code**:
   ```bash
   make all
   ```

3. **Load the bootloader and OS** to the ROM chips:
   - For detailed steps on flashing the ROM, refer to the [Setup Guide](docs/Setup.md).

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
