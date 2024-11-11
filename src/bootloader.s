.include "config.s"

.org 0x00000000
.long 0x1400000     /* Initial Stack Pointer */
.long _start    /* Start of bootloader code */

.section .data            /* Declare data section explicitly */
.align 4                  /* Ensure proper alignment for pointers */

messages:
    .long message0
    .long message1
    .long message2

message0:
	.ascii "Clearing Memory"
	.byte 0
message1:
	.ascii "Disabling Interrupts"
	.byte
message2:
	.ascii "Starting Memory Check"
	.byte

	
.text	

.global _start  
.global _post
.global print_message

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
	
print_message:
/* 
    This section performs the following:
    1. Copies the index to a data register.
    2. Multiplies the index by 4 to access the correct pointer in the messages array.
    3. Loads the address of the message into the address register a0.
*/
	move.l %d0, %d1
	lsl.l  #2, %d1
	movea.l %d1, %a1
	move.l messages(%a1), %a0


print_loop:
    move.b (%a0)+, %d1               /* Load next byte of the message into %d1  */
    beq done_print                   /* If null terminator, were done  */
    jsr uart_send_byte               /* Call uart_send_byte to send character in %d1  */
    bra print_loop                   /* Repeat for next character  */

done_print:
    rts                               /* Return from subroutine */
	
	
/* Bootloader entry point */
_start:
    move.l  #0x200000, %a7  /* Set up stack pointer to top of RAM */
	
	jsr uart_init          /* Initialise UART for QEMU output */

    /* Add further initialisation steps here
    jsr spi_init
    jsr i2c_init
    jsr rtc_check
	 */
	/* Clear registers */
	move.l #0, %d0            /* Load the index of the message (e.g., 0 for "Clearing Memory")*/
    jsr print_message         /* Print the message at messages[0] */
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
	
	move.l #1, %d0            /* Load the index of the message (e.g., 0 for "Disabling Interrupts")*/
    jsr print_message         /* Print the message at messages[1] */	
	
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
	move.l #2, %d0            /* Load the index of the message (e.g., 0 for "Starting Memory Check")*/
    jsr print_message         /* Print the message at messages[2] */	

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

/* Enhanced Memory Check Routine */
memory_check:
    /* Test pattern 1 */
    move.l  #0xA5A5A5A5, %d0         /* Test pattern 1 */
    bsr     memory_pattern_test

    /* Test pattern 2 */
    move.l  #0xAAAAAAAA, %d0          /* Test pattern 2 */
    bsr     memory_pattern_test

    /* Test pattern 3 */
    move.l  #0x55555555, %d0          /* Test pattern 3 */
    bsr     memory_pattern_test

    /* Address test */
    bsr     memory_address_test

    clr.l   %d0                       /* Set return success status */
    rts

memory_test_fail:
    move.l  #1, %d0                   /* Set return failure status */
    rts

/* Memory Pattern Test Subroutine */
memory_pattern_test:
    move.l  #0x200000, %a0            /* Start of test memory region */
    move.l  #0x210000, %a1            /* End of test memory region */

pattern_test_loop:
    move.l  %d0, (%a0)                /* Write pattern to memory */
    move.l  (%a0), %d1                /* Load value from memory into %d1 */
    cmp.l   %d0, %d1                  /* Compare %d0 with %d1 */
    bne     memory_test_fail          /* Branch if check fails */
    addq.l  #4, %a0                   /* Move to the next location */
    cmp.l   %a1, %a0                  /* Check if end of region reached */
    bcs     pattern_test_loop         /* Loop if not finished */
    rts

/* Address-Based Memory Test Subroutine */
memory_address_test:
    move.l  #0x200000, %a0            /* Start of test memory region */
    move.l  #0x210000, %a1            /* End of test memory region */

address_test_loop:
    move.l  %a0, (%a0)                /* Write address value to memory */
    move.l  (%a0), %d1                /* Load value from memory into %d1 */
    cmp.l   %a0, %d1                  /* Compare address with value */
    bne     memory_test_fail          /* Branch if check fails */
    addq.l  #4, %a0                   /* Move to the next location */
    cmp.l   %a1, %a0                  /* Check if end of region reached */
    bcs     address_test_loop         /* Loop if not finished */
    rts


/* Idle loop in case of bootloader failure */
_idle_loop:
    bra _idle_loop

