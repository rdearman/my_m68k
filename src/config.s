    /* config.s: Common Definitions and Constants File */

    /* ===== Memory Addresses ===== */
    .equ ROM_BASE_ADDR, 0x00000000      /* Base address of ROM */
    .equ RAM_BASE_ADDR, 0x00100000      /* Base address of RAM */
    .equ STACK_TOP_ADDR, 0x200000       /* Top of stack in RAM */
    .equ VECTOR_TABLE_ADDR, 0x00000000  /* Base address for interrupt vector table */
    .equ BOOTLOADER_ENTRY, 0x00000000   /* Bootloader start address */
	
	/* ===== VIA (W65C22N6TPG) Configuration ===== */
	.equ VIA_BASE_ADDR, 0x300000              /* Base address for VIA */
	.equ VIA_INTERRUPT_LEVEL, 3               /* Priority level for VIA interrupt */

	/* Register offsets for VIA */
	.equ VIA_DDRA, VIA_BASE_ADDR + 0x00       /* Data Direction Register A */
	.equ VIA_DDRB, VIA_BASE_ADDR + 0x02       /* Data Direction Register B */
	.equ VIA_ORA, VIA_BASE_ADDR + 0x04        /* Output Register A */
	.equ VIA_ORB, VIA_BASE_ADDR + 0x06        /* Output Register B */
	.equ VIA_IRB, VIA_BASE_ADDR + 0x07        /* Input Register B */
	.equ VIA_ACR, VIA_BASE_ADDR + 0x0B        /* Auxiliary Control Register */
	.equ VIA_PCR, VIA_BASE_ADDR + 0x0C        /* Peripheral Control Register */
	.equ VIA_IFR, VIA_BASE_ADDR + 0x0D        /* Interrupt Flag Register */
	.equ VIA_IER, VIA_BASE_ADDR + 0x0E        /* Interrupt Enable Register */	

    /* ===== UART Configuration ===== */
    .equ UART_BASE_ADDR, 0xC00000       /* UART base memory-mapped I/O address */
    .equ UART_INTERRUPT_LEVEL, 1        /* Priority level for UART interrupt */
    .equ UART_BAUD_RATE, 19200			/* UART baud rate setting */
    .equ UART_CTRL_REG, UART_BASE_ADDR + 0x02 /* UART control register offset */
    .equ UART_STATUS_REG, UART_BASE_ADDR + 0x04 /* UART status register offset */

	
    /* ===== SPI Configuration ===== */
    .equ SPI_BASE_ADDR, 0xC00020        /* SPI base memory-mapped I/O address */
    .equ SPI_INTERRUPT_LEVEL, 2         /* Priority level for SPI interrupt */
    .equ SPI_CTRL_REG, SPI_BASE_ADDR + 0x02 /* SPI control register offset */
    .equ SPI_STATUS_REG, SPI_BASE_ADDR + 0x04 /* SPI status register offset */

    /* ===== I2C Configuration ===== */
    .equ I2C_BASE_ADDR, 0xC00040        /* I2C base memory-mapped I/O address */
    .equ I2C_INTERRUPT_LEVEL, 3         /* Priority level for I2C interrupt */
    .equ I2C_CTRL_REG, I2C_BASE_ADDR + 0x02 /* I2C control register offset */
    .equ I2C_STATUS_REG, I2C_BASE_ADDR + 0x04 /* I2C status register offset */

    /* ===== System Control Constants ===== */
    .equ ENABLE_INTERRUPTS, 0x2000      /* Value to enable global interrupts */
    .equ DISABLE_INTERRUPTS, 0x2700     /* Value to disable global interrupts */

    /* ===== Interrupt Levels and Vectors ===== */
    .equ CENTRAL_INTERRUPT_HANDLER, VECTOR_TABLE_ADDR + 0x04 /* Central interrupt handler */
    .equ LEVEL_1_AUTOVECTOR, VECTOR_TABLE_ADDR + 0x40        /* Level 1 autovector */
    .equ LEVEL_2_AUTOVECTOR, VECTOR_TABLE_ADDR + 0x44        /* Level 2 autovector */
    .equ LEVEL_3_AUTOVECTOR, VECTOR_TABLE_ADDR + 0x48        /* Level 3 autovector */
    .equ LEVEL_4_AUTOVECTOR, VECTOR_TABLE_ADDR + 0x4C        /* Level 4 autovector */
    .equ LEVEL_5_AUTOVECTOR, VECTOR_TABLE_ADDR + 0x50        /* Level 5 autovector */
    .equ LEVEL_6_AUTOVECTOR, VECTOR_TABLE_ADDR + 0x54        /* Level 6 autovector */
    .equ LEVEL_7_AUTOVECTOR, VECTOR_TABLE_ADDR + 0x58        /* Level 7 autovector */

    /* ===== Other Constants ===== */
    .equ RESET_VECTOR, VECTOR_TABLE_ADDR /* Reset vector location */
    .equ SPURIOUS_INTERRUPT_VECTOR, VECTOR_TABLE_ADDR + 0x60 /* Spurious interrupt vector */
    .equ TRAP_VECTOR_BASE, VECTOR_TABLE_ADDR + 0x80 /* Base address for TRAP vectors */
    .equ FPU_ERROR_VECTOR, VECTOR_TABLE_ADDR + 0xC0 /* Floating-point error vector */
    .equ MMU_ERROR_VECTOR, VECTOR_TABLE_ADDR + 0xDC /* Memory management unit error vector */
    .equ USER_INTERRUPT_BASE, VECTOR_TABLE_ADDR + 0x100 /* User device interrupt vectors start */

    /* ===== Hardware Specific Configurations ===== */
    /* Placeholder for any additional device configurations, such as GPIO pins, timers, etc. */

    /* ===== Macro Definitions ===== */
    .macro LOAD_VECTOR handler, vector
        lea \handler, %a0
        move.l %a0, \vector
    .endm

    /* config.s: Comprehensive Error Codes for Homebrew 68000 Build */

    /* ===== General/System-Level Error Codes ===== */
    .equ ERR_SUCCESS, 0                /* No error */
    .equ ERR_UNKNOWN, -1               /* Unknown error */
    .equ ERR_INVALID_PARAM, -2         /* Invalid parameter */
    .equ ERR_TIMEOUT, -3               /* Operation timed out */
    .equ ERR_UNSUPPORTED_OP, -4        /* Unsupported operation */
    .equ ERR_INITIALISATION_FAIL, -5   /* General initialisation failure */

    /* ===== Memory Errors ===== */
    .equ ERR_MEMORY_ALLOCATION_FAIL, -10   /* Memory allocation failure */
    .equ ERR_MEMORY_OUT_OF_BOUNDS, -11     /* Access out of bounds */
    .equ ERR_MEMORY_CHECK_FAIL, -12        /* Memory check failure */

    /* ===== CPU Errors ===== */
    .equ ERR_CPU_PRIVILEGE_VIOLATION, -20  /* Privilege violation */
    .equ ERR_CPU_ILLEGAL_INSTRUCTION, -21  /* Illegal instruction encountered */
    .equ ERR_CPU_ADDRESS_ERROR, -22        /* Address error */
    .equ ERR_CPU_BUS_ERROR, -23            /* Bus error */

    /* ===== UART Errors ===== */
    .equ ERR_UART_INIT_FAIL, -30           /* UART initialisation failed */
    .equ ERR_UART_TIMEOUT, -31             /* UART timeout during transmission/reception */
    .equ ERR_UART_BUFFER_OVERFLOW, -32     /* UART buffer overflow */
    .equ ERR_UART_PARITY_ERROR, -33        /* UART parity error */
    .equ ERR_UART_FRAME_ERROR, -34         /* UART framing error */
    .equ ERR_UART_DEVICE_NOT_RESPONDING, -35 /* UART device not responding */

    /* ===== SPI Errors ===== */
    .equ ERR_SPI_INIT_FAIL, -40            /* SPI initialisation failed */
    .equ ERR_SPI_TIMEOUT, -41              /* SPI operation timeout */
    .equ ERR_SPI_DEVICE_NOT_FOUND, -42     /* SPI device not found on the bus */
    .equ ERR_SPI_TRANSFER_FAIL, -43        /* SPI data transfer failure */

    /* ===== I2C Errors ===== */
    .equ ERR_I2C_INIT_FAIL, -50            /* I2C initialisation failed */
    .equ ERR_I2C_TIMEOUT, -51              /* I2C operation timeout */
    .equ ERR_I2C_DEVICE_NOT_FOUND, -52     /* I2C device not found on the bus */
    .equ ERR_I2C_ARBITRATION_LOST, -53     /* I2C arbitration lost */
    .equ ERR_I2C_ACK_NOT_RECEIVED, -54     /* ACK not received from I2C slave */

    /* ===== SD Card/Storage Errors ===== */
    .equ ERR_SD_INIT_FAIL, -60             /* SD card initialisation failure */
    .equ ERR_SD_TIMEOUT, -61               /* SD card operation timeout */
    .equ ERR_SD_READ_FAIL, -62             /* SD card read failure */
    .equ ERR_SD_WRITE_FAIL, -63            /* SD card write failure */
    .equ ERR_SD_NOT_DETECTED, -64          /* SD card not detected */

    /* ===== LCD Display Errors ===== */
    .equ ERR_LCD_INIT_FAIL, -70            /* LCD initialisation failed */
    .equ ERR_LCD_WRITE_FAIL, -71           /* LCD write operation failed */
    .equ ERR_LCD_DEVICE_NOT_RESPONDING, -72 /* LCD device not responding */

    /* ===== Real-Time Clock (RTC) Errors ===== */
    .equ ERR_RTC_INIT_FAIL, -80            /* RTC initialisation failure */
    .equ ERR_RTC_TIMEOUT, -81              /* RTC operation timeout */
    .equ ERR_RTC_READ_FAIL, -82            /* RTC read failure */
    .equ ERR_RTC_WRITE_FAIL, -83           /* RTC write failure */
    .equ ERR_RTC_DEVICE_NOT_FOUND, -84     /* RTC device not found */

    /* ===== Network/ENC28J60 Errors ===== */
    .equ ERR_NET_INIT_FAIL, -90            /* Network module initialisation failure */
    .equ ERR_NET_TIMEOUT, -91              /* Network operation timeout */
    .equ ERR_NET_DEVICE_NOT_FOUND, -92     /* Network device not found */
    .equ ERR_NET_TRANSMIT_FAIL, -93        /* Network transmit failure */
    .equ ERR_NET_RECEIVE_FAIL, -94         /* Network receive failure */

    /* ===== GPIO (General Purpose Input/Output) Errors ===== */
    .equ ERR_GPIO_INIT_FAIL, -100          /* GPIO initialisation failed */
    .equ ERR_GPIO_PIN_UNAVAILABLE, -101    /* GPIO pin unavailable */
    .equ ERR_GPIO_INVALID_DIRECTION, -102  /* Invalid GPIO direction */
    .equ ERR_GPIO_WRITE_FAIL, -103         /* GPIO write operation failed */
    .equ ERR_GPIO_READ_FAIL, -104          /* GPIO read operation failed */

    /* ===== Power and Reset Errors ===== */
    .equ ERR_RESET_FAIL, -110              /* System reset failure */
    .equ ERR_POWER_FAIL, -111              /* Power failure detected */
    .equ ERR_BROWNOUT_DETECTED, -112       /* Brownout condition detected */



    /* ===== Timeout and Error Codes ===== */
    .equ SPI_TIMEOUT_LIMIT, 1000            /* Arbitrary limit for SPI timeout */
    .equ I2C_TIMEOUT_LIMIT, 1000            /* Arbitrary limit for I2C timeout */
    .equ SPI_ERROR_CODE, -1                 /* Error code for SPI failure */
    .equ I2C_ERROR_CODE, -1                 /* Error code for I2C failure */
