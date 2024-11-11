.include "config.s"
.section .text
.global via_init

#ifdef QEMU
    .ascii "Compiling for QEMU\n"
#else
    .ascii "Compiling for hardware\n"
#endif


/* VIA Initialisation Code */
via_init:
    /* Configure Data Direction for Port B */
    move.b #0x3F, VIA_DDRB       /* Set PB0-PB5 as outputs for SPI (PB0-PB2), I2C (PB4-PB5) */
    move.b #0x00, VIA_DDRA       /* Set Port A as input by default */

    /* Set up the Auxiliary Control Register (ACR) for timer and control functionality */
    move.b #0x80, VIA_ACR        /* Configure Timer 1 in free-running mode for SPI clock generation */
    
#ifdef QEMU
#else
    move.b #0x40, VIA_ACR        /* Set Timer 2 for square wave generation on PB6 for UART clock */

    /* Configure Timer 2 for UART clock generation using UART_BAUD_RATE */
    move.l #8000000, %d0                   /* System clock frequency (8 MHz) */
    move.l #UART_BAUD_RATE, %d1            /* Load UART baud rate (e.g., 9600) */
    lsl.l #1, %d1                          /* Multiply baud rate by 2 */
    divu %d1, %d0                          /* Divide system clock by (2 * baud rate) */
    subi.l #1, %d0                         /* Subtract 1 from result */
    move.w %d0, VIA_T2C_L                  /* Load Timer 2 counter with calculated value */
#endif

    /* Configure Peripheral Control Register (PCR) for handshake and interrupt options */
    move.b #0x1C, VIA_PCR        /* Set PCR for handshaking on Port B */

    /* Enable interrupts for SPI and I2C operations */
    move.b #0xA0, VIA_IER        /* Enable interrupt for CA1 and CA2 (I2C and SPI conditions) */

    /* Set initial output values on Port B */
    move.b #0x30, VIA_ORB        /* Set PB4 (SCL) and PB5 (SDA) as outputs for I2C, PB0-PB2 as SPI */
    
    rts
