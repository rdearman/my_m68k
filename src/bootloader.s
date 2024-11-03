.org 0x00000000
# .long 0x00200000 /* Initial stack pointer */
.long 0x1400000     /* Initial Stack Pointer */
.long _start    /* Start of bootloader code */

.global _start  
.global _post

/* External functions for device initialisation */
.extern spi_init, spi_check, i2c_init, rtc_check
.extern sd_init, sd_check, lcd_init, lcd_check
.extern uart_check

/* Conditional entry for monitor */
MONITOR_ENTRY:
.if MONITOR_ENTRY != 0
    jmp MONITOR_ENTRY
.else
    jmp _idle_loop
.endif
	
/* Bootloader entry point */
_start:
    move.l  #0x200000, %a7  /* Set up stack pointer to top of RAM */
	/* Clear registers */
    clr.l %d0
    clr.l %d1
    clr.l %d2
    clr.l %d3
    clr.l %d4
    clr.l %d5
    clr.l %d6
    clr.l %d7

    move.l #0, %a0
    move.l #0, %a1
    move.l #0, %a2
    move.l #0, %a3
    move.l #0, %a4
    move.l #0, %a5
    move.l #0, %a6
	
    move.w  #0x2700, %sr    /* Disable interrupts */

    jsr _post               /* Call POST (Power-On Self Test) */

    /* Jump to monitor if available */
    jmp MONITOR_ENTRY
	
    bra _idle_loop          /* Stay here if no monitor or POST fails */

/* Monitor Start (when WITH_MONITOR is defined) */
monitor_start:
    lea MONITOR_ENTRY, %a0
    jmp (%a0)               /* Jump to monitor start */

/* POST - Power-On Self-Test */
_post:
    /* Memory Check */
    jsr memory_check
    beq memory_fail         /* Branch if memory test fails */

    /* UART Check */
    jsr uart_check
    beq uart_fail           /* Branch if UART test fails */

    /* SPI Check */
    jsr spi_init
    jsr spi_check
    beq spi_fail

    /* I2C and RTC Check */
    jsr i2c_init
    jsr rtc_check
    beq rtc_fail

    /* SD Card Check */
    jsr sd_init
    jsr sd_check
    beq sd_fail

    /* LCD Check */
    jsr lcd_init
    jsr lcd_check
    beq lcd_fail

    /* All tests passed */
    move.l  #0x01, %d0
    bra post_complete

memory_fail:
    move.l  #0x02, %d0
    bra post_error

uart_fail:
    move.l  #0x03, %d0
    bra post_error

spi_fail:
    move.l  #0x04, %d0
    bra post_error

rtc_fail:
    move.l  #0x05, %d0
    bra post_error

sd_fail:
    move.l  #0x06, %d0
    bra post_error

lcd_fail:
    move.l  #0x07, %d0
    bra post_error

post_error:
    /* Output error code in %d0 */
    rts

post_complete:
    /* Code to signal POST completion (e.g., lighting an LED, outputting over serial) */
    rts

/* Memory Check Routine */
memory_check:
    move.l  #0xA5A5A5A5, %d0         /* Test pattern */
    move.l  #0x200000, %a0            /* Start of test memory region */
    move.l  #0x210000, %a1            /* End of test memory region */

memory_test_loop:
    move.l  %d0, (%a0)                /* Write pattern to memory */
    move.l  (%a0), %d1                /* Load value from memory into %d1 */
    cmp.l   %d0, %d1                  /* Compare %d0 with %d1 */
    bne     memory_test_fail          /* Branch if check fails */
    addq.l  #4, %a0                   /* Move to the next location */
    cmp.l   %a1, %a0                  /* Check if end of region reached */
    bcs     memory_test_loop          /* Loop if not finished */
    clr.l   %d0                       /* Set return success status */
    rts

memory_test_fail:
    move.l  #1, %d0                   /* Set return failure status */
    rts

/* Idle loop in case of bootloader failure */
_idle_loop:
    bra _idle_loop
