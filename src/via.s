
.section .text
.global via_init

via_init:
    /* Initialize VIA for I2C, SPI, and Chip Selects */
    move.b #0x30, 0x300000      /* PB4 (SCL) and PB5 (SDA) as outputs, PB0-PB2 as SPI lines */
    rts
    