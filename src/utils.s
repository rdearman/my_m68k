.include "config.s"
.section .text
.global report_error, set_debug_output
.extern uart_send_byte, lcd_send_message, modvga_display_error

/* Error output device options */
DEBUG_UART   =   0
DEBUG_LCD    =  1
DEBUG_MODVGA = 2


/* Default debug output device */
	.align 2
debug_output_device: .byte DEBUG_UART  /* Default to UART */

	/* Set Debug Output Device */
	.align 2
set_debug_output:
    move.b %d0, debug_output_device     /* %d0 should contain desired output device ID */
    rts

/* Report Error Function */
/* Inputs: 
   %d0 - Error code
   Outputs an error message to the selected debug output.
*/
	.align 2
report_error:
    /* Load the error message prefix */
    move.l #error_prefix, %a0
    jsr print_message                  /* Print "Error: " prefix */
    
    /* Load and print the error code */
    move.b %d0, %d1                    /* Copy error code to %d1 for output */
    jsr print_error_code               /* Print the error code */

    rts

/* Helper function to print a message to the current debug output */
	.align 2
print_message:
    cmp.b #DEBUG_UART, debug_output_device
    beq uart_send_message
    cmp.b #DEBUG_LCD, debug_output_device
    beq lcd_send_message
    cmp.b #DEBUG_MODVGA, debug_output_device
    beq modvga_display_message
    rts

/* Print error code as a byte */
	.align 2
print_error_code:
    /* Convert %d1 to ASCII if necessary, then output to current debug device */
    jsr print_message
    rts

	.align 2
uart_send_message:
    move.l (%a0), %d1                   /* Load first byte of message */
uart_send_loop:
    jsr uart_send_byte
    addq.l #1, %a0
    tst.b (%a0)                         /* Check for end of string */
    bne uart_send_loop
    rts

	.align 2
lcd_send_message:
    /* Implement sending message to LCD here */
    rts

	.align 2
modvga_display_message:
    /* Implement sending message to MOD-VGA here */
    rts

	.align 2
/* Message prefix for errors */
error_prefix:
    .ascii "Error: "
    .byte 0


/* ===== Standardised Utility Functions ===== */
.global delay, set_bit, clear_bit, toggle_bit, mem_copy, mem_set

/* Basic Delay Function */
delay:
    move.l %d0, %d1                       /* Load delay count from %d0 */
delay_loop:
    subq.l #1, %d1                        /* Decrement counter */
    bne delay_loop                        /* Continue until zero */
    rts

/* Set a Specific Bit in a Register */
set_bit:
    /* %a0 should point to the register, %d0 should hold the bit number */
    bset %d0, (%a0)                       /* Set specified bit */
    rts

/* Clear a Specific Bit in a Register */
clear_bit:
    /* %a0 should point to the register, %d0 should hold the bit number */
    bclr %d0, (%a0)                       /* Clear specified bit */
    rts

/* Toggle a Specific Bit in a Register */
toggle_bit:
    /* %a0 should point to the register, %d0 should hold the bit number */
    btst %d0, (%a0)                       /* Test bit */
    bne clear_toggle                      /* If bit is set, clear it */
    bset %d0, (%a0)                       /* If clear, set it */
    rts
clear_toggle:
    bclr %d0, (%a0)                       /* Clear bit */
    rts

/* Memory Copy Function */
mem_copy:
    /* %a0: Source address, %a1: Destination address, %d0: Number of bytes */
copy_loop:
    move.b (%a0)+, (%a1)+                 /* Copy byte from source to destination */
    subq.l #1, %d0                        /* Decrement count */
    bne copy_loop                         /* Repeat until count reaches zero */
    rts

/* Memory Set Function */
mem_set:
    /* %a0: Destination address, %d1: Value to set, %d0: Number of bytes */
set_loop:
    move.b %d1, (%a0)+                    /* Set byte in destination */
    subq.l #1, %d0                        /* Decrement count */
    bne set_loop                          /* Repeat until count reaches zero */
    rts


/* ===== String Handling Utilities ===== */
.global int_to_hex, int_to_dec

/* Convert Integer to Hexadecimal String (stored in %a0) */
int_to_hex:
    /* %d0: Input integer, %a0: Output buffer address */
    moveq #8, %d1                     /* Process 8 hex digits for 32-bit integer */
    int_to_hex_loop:
        move.l %d0, %d2               /* Copy input integer to %d2 */
        and.l #0xF0000000, %d2        /* Mask the highest nibble */
        lsr.l #28, %d2                /* Shift to lower 4 bits */
        add.b #'0', %d2               /* Convert to ASCII '0'..'9' */
        cmp.b #9, %d2                 /* If > 9, convert to 'A'..'F' */
        ble int_to_hex_skip
        add.b #7, %d2
    int_to_hex_skip:
        move.b %d2, (%a0)+            /* Store character in buffer */
        lsl.l #4, %d0                 /* Shift left to process next nibble */
        subq.l #1, %d1                /* Decrement digit count */
        bne int_to_hex_loop           /* Repeat until all digits processed */
    move.b #0, (%a0)                  /* Null-terminate string */
    rts

/* Convert Integer to Decimal String (stored in %a0) */
int_to_dec:
    /* %d0: Input integer, %a0: Output buffer address */
    clr.l %d1                         /* Clear divisor for repeated subtraction */
    moveq #10, %d2                    /* Set divisor to 10 for decimal conversion */
    move.l %d0, %d3                   /* Copy integer to %d3 */
    lea  -12(%sp), %sp                /* Reserve space for 12-digit buffer on stack */
    movea.l %sp, %a1                  /* Temporary buffer in %a1 */
int_to_dec_loop:
    divu %d2, %d3                     /* Divide integer by 10, quotient in %d3 */
    mulu #10, %d3, %d1                /* Multiply quotient to restore remainder */
    sub.l %d1, %d0                    /* Remainder in %d0 */
    add.b #'0', %d0                   /* Convert remainder to ASCII */
    move.b %d0, (%a1)+                /* Store in buffer */
    move.l %d3, %d0                   /* Update integer with quotient */
    tst.l %d3                         /* Check if quotient is zero */
    bne int_to_dec_loop               /* Repeat if not zero */

    /* Copy result to output buffer in reverse order */
    movea.l %a1, %a1                  /* Start from temporary buffer */
int_to_dec_copy:
    move.b -(%a1), (%a0)+             /* Copy each byte to output buffer */
    tst.b (%a1)                       /* Check for end of buffer */
    bne int_to_dec_copy
    move.b #0, (%a0)                  /* Null-terminate string */
    lea 12(%sp), %sp                  /* Restore stack */
    rts
