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
