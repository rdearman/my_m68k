.include "config.s"
.section .text
.global via_init

/* VIA Initialisation Code */
via_init:
    /* Configure Data Direction for Port B */
    move.b #0x3F, VIA_DDRB       /* Set PB0-PB5 as outputs for SPI (PB0-PB2), I2C (PB4-PB5) */
    move.b #0x00, VIA_DDRA       /* Set Port A as input by default */

    /* Set up the Auxiliary Control Register (ACR) for timer and control functionality */
    move.b #0x80, VIA_ACR        /* Configure Timer 1 in free-running mode for SPI clock generation */

    /* Configure Peripheral Control Register (PCR) for handshake and interrupt options */
    move.b #0x1C, VIA_PCR        /* Set PCR for handshaking on Port B */

    /* Enable interrupts for SPI and I2C operations */
    move.b #0xA0, VIA_IER        /* Enable interrupt for CA1 and CA2 (I2C and SPI conditions) */

    /* Set initial output values on Port B */
    move.b #0x30, VIA_ORB        /* Set PB4 (SCL) and PB5 (SDA) as outputs for I2C, PB0-PB2 as SPI */

    rts                          /* Return from subroutine */