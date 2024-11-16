.include "config.s"
.section .text
.global uart_init, uart_send_byte, uart_receive_byte, uart_check, set_baud_rate
.global uart_send_string

/* Base address for the SCC2692 DUART */
.equ UART_BASE, 0x40000000

/* Register offsets from the base address */
.equ UART_MR, UART_BASE          /* Mode Register (MR1A/MR2A) */
.equ UART_SR, UART_BASE + 1      /* Status Register (SRA) */
.equ UART_CR, UART_BASE + 2      /* Command Register (CRA) */
.equ UART_RHR, UART_BASE + 3     /* Receive Holding Register (RHR) */
.equ UART_THR, UART_BASE + 3     /* Transmit Holding Register (THR) */
.equ UART_CSR, UART_BASE + 4     /* Clock Select Register (CSRA) */
.equ UART_ACR, UART_BASE + 5     /* Auxiliary Control Register (ACR) */
.equ UART_IMR, UART_BASE + 7     /* Interrupt Mask Register (IMR) */

/* UART Initialisation Routine */
uart_init:
    move.b  #0x20, UART_CR       /* Reset MR pointer */
    move.b  #0x13, UART_MR       /* Configure MR1A: 8 Data Bits, No Parity */
    move.b  #0x07, UART_MR       /* Configure MR2A: 1 Stop Bit, Normal Mode */
    move.b  #0xC0, UART_CSR      /* Set baud rate to 19.2 kbps (CSR = 1100) */
    move.b  #0x80, UART_ACR      /* Enable Baud Rate Generator */
    move.b  #0x05, UART_CR       /* Enable Transmitter and Receiver */
    move.b  #0x00, UART_IMR      /* Disable all interrupts */
    rts

/* UART Self-Check Routine */
uart_check:
    move.b  #0xFF, UART_THR      /* Write a test byte (0xFF) to Transmit Holding Register */
    jsr uart_wait_transmit       /* Wait until transmit buffer is ready */

    jsr uart_wait_receive        /* Wait until receive buffer has data */
    move.b  UART_RHR, %d0        /* Read received byte into %d0 */
    cmpi.b  #0xFF, %d0           /* Compare read byte with test byte (0xFF) */
    bne     uart_fail            /* Branch if test fails */

    clr.l   %d0                  /* Clear %d0 to indicate success */
    rts

uart_fail:
    move.l  #1, %d0              /* Set failure code in %d0 */
    rts

/* Send a string over UART */
uart_send_string:
    movea.l %a0, %a1             /* Load the address of the string into A1 */
    
uart_send_string_loop:
    move.b  (%a1)+, %d1          /* Load the next character from the string into D1 and increment A1 */
    tst.b   %d1                  /* Check if the character is null (0x00) */
    beq     uart_send_string_done /* If null, end the loop */
    jsr     uart_send_byte       /* Call uart_send_byte to transmit the character */
    bra     uart_send_string_loop /* Loop back for the next character */

uart_send_string_done:
    rts                          /* Return when the string is fully sent */

/* Send a byte over UART */
uart_send_byte:
    move.b %d1, UART_THR         /* Load byte from %d1 into Transmit Holding Register */
    jsr uart_wait_transmit       /* Use shared transmit wait routine */
    rts

/* Receive a byte over UART */
uart_receive_byte:
    jsr uart_wait_receive        /* Use shared receive wait routine */
    move.b UART_RHR, %d1         /* Move received byte from Receive Holding Register to %d1 */
    rts

/* Helper routine to wait for UART transmit buffer to be ready */
uart_wait_transmit:
    move.l #50000, %d2           /* Timeout counter (adjusted for 8 MHz) */
wait_transmit_loop:
    btst    #2, UART_SR          /* Check if TX Ready (Bit 2 of SRA) */
    bne     wait_transmit_done   /* If ready, continue */
    subq.l  #1, %d2              /* Decrement timeout counter */
    bne     wait_transmit_loop   /* Loop if counter > 0 */
    bra     uart_fail            /* If timeout reached, branch to error handler */

wait_transmit_done:
    rts

/* Helper routine to wait for UART receive buffer to have data */
uart_wait_receive:
    move.l #50000, %d2           /* Timeout counter (adjusted for 8 MHz) */
wait_receive_loop:
    btst    #0, UART_SR          /* Check if RX Ready (Bit 0 of SRA) */
    bne     wait_receive_done    /* If data received, continue */
    subq.l  #1, %d2              /* Decrement timeout counter */
    bne     wait_receive_loop    /* Loop if counter > 0 */
    bra     uart_fail            /* If timeout reached, branch to error handler */

wait_receive_done:
    rts
