.include "config.s"
.section .text
.global i2c_init, i2c_start, i2c_stop, i2c_write_byte, i2c_read_byte, i2c_check

/* I2C Macros for Start, Stop, Read, Write */
.macro I2C_START
    bset #4, 0x300000                /* Set SCL high */
    bclr #5, 0x300000                /* Set SDA low */
    bclr #4, 0x300000                /* Set SCL low */
.endm

.macro I2C_STOP
    bclr #5, 0x300000                /* Set SDA low */
    bset #4, 0x300000                /* Set SCL high */
    bset #5, 0x300000                /* Set SDA high */
.endm

.macro I2C_WRITE
    move.b %d0, 0x300001             /* Write byte to SDA register */
.endm

.macro I2C_READ
    move.b 0x300001, %d0             /* Read byte from SDA register */
.endm

/* I2C Initialisation with Bus Readiness Check */
i2c_init:
    I2C_START
    move.l  #0xFFFF, %d2             /* Timeout counter */
i2c_init_wait:
    btst   #5, 0x300000              /* Check if SDA line is high */
    bne    i2c_init_done
    subq.l #1, %d2
    bne    i2c_init_wait
    move.b #1, %d0                   /* Error: bus not ready */
    rts
i2c_init_done:
    I2C_STOP
    clr.b %d0                        /* Success code */
    rts

/* I2C Start Condition with Return Code */
i2c_start:
    I2C_START
    move.l  #0xFFFF, %d2             /* Timeout counter */
i2c_wait_start:
    btst   #4, 0x300000              /* Wait for SCL to go high */
    beq    i2c_start_done
    subq.l #1, %d2
    bne    i2c_wait_start
    move.b #1, %d0                   /* Timeout error */
    rts
i2c_start_done:
    clr.b %d0                        /* Success */
    rts

/* I2C Stop Condition with Return Code */
i2c_stop:
    I2C_STOP
    move.l  #0xFFFF, %d2             /* Timeout counter */
i2c_wait_stop:
    btst   #5, 0x300000              /* Wait for SDA to go high */
    beq    i2c_stop_done
    subq.l #1, %d2
    bne    i2c_wait_stop
    move.b #1, %d0                   /* Timeout error */
    rts
i2c_stop_done:
    clr.b %d0                        /* Success */
    rts

/* I2C Write Byte with Return Code */
i2c_write_byte:
    movem.l %d0/%d1, -(%sp)          /* Preserve registers */
    move.b  %d0, %d1                 /* Load byte to send in %d1 */
    move.l  #8, %d0                  /* 8 bits to write */

i2c_write_loop:
    btst    #7, %d1
    bne     i2c_write_one
    bclr    #5, 0x300000             /* Clear SDA for 0 */
    bra     i2c_write_next_bit

i2c_write_one:
    bset    #5, 0x300000             /* Set SDA for 1 */

i2c_write_next_bit:
    bset    #4, 0x300000             /* Set SCL high (clock pulse) */
    bclr    #4, 0x300000             /* Clear SCL low */
    lsl.b   #1, %d1                  /* Shift next bit */
    subq.l  #1, %d0                  /* Decrement bit count */
    bne     i2c_write_loop           /* Continue if not done */

    /* Check for ACK */
    bset    #5, 0x300000             /* Release SDA for ACK */
    bset    #4, 0x300000             /* Clock ACK bit */
    btst    #5, 0x300000             /* Check if ACK received */
    beq     i2c_write_ack_received   /* ACK received if SDA low */
    move.b  #1, %d0                  /* Failure code */
    bra     i2c_write_end

i2c_write_ack_received:
    clr.b   %d0                      /* Success code */

i2c_write_end:
    bclr    #4, 0x300000             /* Clear SCL */
    movem.l (%sp)+, %d0/%d1          /* Restore registers */
    rts

/* I2C Read Byte with Return Code */
i2c_read_byte:
    movem.l %d0/%d1, -(%sp)          /* Preserve registers */
    move.l  #8, %d0                  /* 8 bits to read */
    clr.l   %d1                      /* Clear %d1 for incoming byte */

i2c_read_loop:
    bset    #4, 0x300000             /* Set SCL high */
    btst    #5, 0x300000             /* Read data bit from SDA */
    bset    #0, %d1                  /* Set corresponding bit in %d1 */
    bclr    #4, 0x300000             /* Set SCL low */
    lsl.b   #1, %d1                  /* Shift read bit */
    subq.l  #1, %d0                  /* Decrement bit count */
    bne     i2c_read_loop            /* Continue if not done */

    clr.b   %d0                      /* Success */
    rts

i2c_read_end:
    movem.l (%sp)+, %d0/%d1          /* Restore registers */
    rts


/* I2C Timeout and Error Checking */

.global i2c_write_byte_with_timeout, i2c_read_byte_with_timeout

/* I2C Write with Timeout */
i2c_write_byte_with_timeout:
    move.l #I2C_TIMEOUT_LIMIT, %d1           /* Load timeout limit */
write_retry:
    jsr i2c_write_byte                       /* Attempt I2C write */
    tst.b %d0                                /* Check if write was successful */
    bne write_done                           /* If success, exit */
    subq.l #1, %d1                           /* Decrement timeout counter */
    bne write_retry                          /* Retry if timeout not reached */
    move.l #I2C_ERROR_CODE, %d0              /* Set error code on timeout */
write_done:
    rts

/* I2C Read with Timeout */
i2c_read_byte_with_timeout:
    move.l #I2C_TIMEOUT_LIMIT, %d1           /* Load timeout limit */
read_retry:
    jsr i2c_read_byte                        /* Attempt I2C read */
    tst.b %d0                                /* Check if read was successful */
    bne read_done                            /* If success, exit */
    subq.l #1, %d1                           /* Decrement timeout counter */
    bne read_retry                           /* Retry if timeout not reached */
    move.l #I2C_ERROR_CODE, %d0              /* Set error code on timeout */
read_done:
    rts
