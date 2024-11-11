.include "config.s"
.section .text
.global uart_init, uart_send_byte, uart_receive_byte, uart_check
#ifdef QEMU
    .equ UART_DATA_REG, 0x40000200
#else
    .equ UART_DATA_REG, 0x400000    /* Real hardware UART address */
#endif


/* UART Initialisation Routine */
uart_init:
    move.b  #0x03, UART_DATA_REG+2       /* Set UART control register for 8N1, no parity */
    move.b  #0x05, UART_DATA_REG+4       /* Set UART baud rate to desired value */
    rts

/* UART Self-Check Routine */
uart_check:
    move.b  #0xFF, UART_DATA_REG      /* Write a test byte (0xFF) to UART data register */
    jsr uart_wait_transmit       /* Wait until transmit buffer is ready */

    move.b  UART_DATA_REG, %d0        /* Read back from UART data register into %d0 */
    cmpi.b  #0xFF, %d0           /* Compare read byte with test byte (0xFF) */
    bne     uart_fail            /* Branch if test fails */

    clr.l   %d0                  /* Clear %d0 to indicate success */
    rts

uart_fail:
    move.l  #1, %d0              /* Set failure code in %d0 */
    rts

/* Send a byte over UART */
uart_send_byte:
    move.b %d1, UART_DATA_REG         /* Load byte from %d1 into UART data register */
    jsr uart_wait_transmit       /* Use shared transmit wait routine */
    rts

/* Receive a byte over UART */
uart_receive_byte:
    jsr uart_wait_receive        /* Use shared receive wait routine */
    move.b UART_DATA_REG, %d1         /* Move received byte from UART data register to %d1 */
    rts

uart_wait_transmit:
    move.l #10000, %d2                /* Set a timeout counter */
wait_transmit_done:
    btst    #5, UART_STATUS_REG       /* Test if the transmit buffer is ready (check bit 5) */
    beq     wait_transmit_done        /* Loop until buffer is ready */
    dbra    %d2, wait_transmit_done   /* Decrement timeout counter */
    rts                                /* Return when ready or on timeout */


/* Helper routine to wait for UART transmit buffer to be ready */
uart_wait_transmit:
    move.l #10000, %d2           /* Timeout counter */
wait_transmit_loop:
    btst    #5, UART_DATA_REG+2          /* Check if transmit buffer is ready */
    beq     wait_transmit_done   /* If ready, continue */
    subq.l  #1, %d2              /* Decrement timeout counter */
    bne     wait_transmit_loop   /* Loop if counter > 0 */
    bra     uart_fail            /* If timeout reached, branch to error handler */

wait_transmit_done:
    rts

/* Helper routine to wait for UART receive buffer to have data */
uart_wait_receive:
    move.l #10000, %d2           /* Timeout counter */
wait_receive_loop:
    btst    #0, UART_DATA_REG+2          /* Check if receive buffer has data */
    bne     wait_receive_done    /* If data received, continue */
    subq.l  #1, %d2              /* Decrement timeout counter */
    bne     wait_receive_loop    /* Loop if counter > 0 */
    bra     uart_fail            /* If timeout reached, branch to error handler */

wait_receive_done:
    rts

