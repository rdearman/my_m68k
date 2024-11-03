.section .text
.global set_interface, write_stdout, write_stderr, read_stdin, mem_dump

/* Define interface types */
#define INTERFACE_UART  0
#define INTERFACE_MODVGA 1

/* Active interface variable (defaults to UART) */
active_interface:
    .byte INTERFACE_UART          /* Default to UART for stdout and stdin */

/* Set the active interface */
set_interface:
    move.b %d0, active_interface   /* Set %d0 as active interface (0 = UART, 1 = MODVGA) */
    rts

/* Write to stdout */
write_stdout:
    cmp.b #INTERFACE_UART, active_interface
    beq write_to_uart
    bne write_to_modvga

write_to_uart:
    jsr uart_write                 /* Call UART write function with data in %a0 */
    rts

write_to_modvga:
    jsr modvga_write               /* Call MOD-VGA write function with data in %a0 */
    rts

/* Write to stderr (always outputs to UART) */
write_stderr:
    jsr uart_write                 /* Send data in %a0 directly to UART */
    rts

/* Read from stdin */
read_stdin:
    cmp.b #INTERFACE_UART, active_interface
    beq read_from_uart
    bne read_from_modvga

read_from_uart:
    jsr uart_read                  /* Read from UART, result in %d0 */
    rts

read_from_modvga:
    jsr modvga_read                /* Read from MOD-VGA, result in %d0 */
    rts

/* Memory Dump Function (outputs in hexadecimal format over stdout) */
mem_dump:
    move.l %a0, %a1                /* Start address in %a0 */
    move.l %d0, %d1                /* Length in bytes in %d0 */
    moveq  #16, %d2                /* Set width (16 bytes per line) */

dump_loop:
    moveq  #0, %d3                 /* Line byte counter */
    cmp.l  %d1, %d3                /* Check if length has been exhausted */
    beq end_dump

    move.l %a1, %a0                /* Load address */
    jsr write_stdout               /* Output address */
    moveq  #':' , %d3
    jsr write_stdout               /* Print separator */

byte_loop:
    move.b (%a1)+, %d0             /* Read byte */
    jsr write_stdout               /* Output byte in hex format */
    addq.l #1, %d3
    cmp.w  %d2, %d3
    blt byte_loop

    jsr newline                    /* Print newline after each line */
    subq.l #16, %d1
    cmp.l  %d1, #0
    bgt dump_loop

end_dump:
    rts
