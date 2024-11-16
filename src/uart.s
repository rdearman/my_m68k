.include "config.s"
.section .text
.global uart_init, uart_send_byte, uart_receive_byte, uart_check, set_baud_rate, uart_send_string

/* Base addresses for each channel */
.equ UART_BASE, 0x40000000
.equ UART_CHANNEL_A_BASE, UART_BASE       /* Channel A base address */
.equ UART_CHANNEL_B_BASE, UART_BASE + 8   /* Channel B base address (offset 0x08) */

/* Compute channel base address */
select_channel:
    cmpi.b  #0, %d1               /* Check if %d1 (channel flag) is 0 (Channel A) */
    beq    .use_channel_a
    movea.l #UART_CHANNEL_B_BASE, %a0 /* Use Channel B */
    rts
.use_channel_a:
    movea.l #UART_CHANNEL_A_BASE, %a0 /* Use Channel A */
    rts

/* UART Initialisation Routine */
uart_init:
    /* Initialise Channel A */
    move.b  #0, %d1              /* Select Channel A */
    jsr     select_channel
    move.b  #0x20, (%a0 + 2)     /* Reset MR pointer */
    move.b  #0x13, (%a0 + 0)     /* Configure MR1A: 8 Data Bits, No Parity */
    move.b  #0x07, (%a0 + 0)     /* Configure MR2A: 1 Stop Bit, Normal Mode */
    move.b  #0xC0, (%a0 + 4)     /* Set baud rate to 19.2 kbps */
    move.b  #0x80, (%a0 + 5)     /* Enable Baud Rate Generator */
    move.b  #0x05, (%a0 + 2)     /* Enable Transmitter and Receiver */
    move.b  #0x00, (%a0 + 7)     /* Disable all interrupts */

    /* Initialise Channel B */
    move.b  #1, %d1              /* Select Channel B */
    jsr     select_channel
    move.b  #0x20, (%a0 + 2)     /* Reset MR pointer */
    move.b  #0x13, (%a0 + 0)     /* Configure MR1A: 8 Data Bits, No Parity */
    move.b  #0x07, (%a0 + 0)     /* Configure MR2A: 1 Stop Bit, Normal Mode */
    move.b  #0xC0, (%a0 + 4)     /* Set baud rate to 19.2 kbps */
    move.b  #0x80, (%a0 + 5)     /* Enable Baud Rate Generator */
    move.b  #0x05, (%a0 + 2)     /* Enable Transmitter and Receiver */
    move.b  #0x00, (%a0 + 7)     /* Disable all interrupts */
    rts

/* UART Self-Check Routine */
uart_check:
    jsr     select_channel       /* Determine base address for the channel (%a0) */
    move.b  #0xFF, (%a0 + 3)     /* Write a test byte (0xFF) to Transmit Holding Register (THR) */
    jsr     uart_wait_transmit   /* Wait until transmit buffer is ready */

    jsr     uart_wait_receive    /* Wait until receive buffer has data */
    move.b  (%a0 + 3), %d0       /* Read received byte into %d0 */
    cmpi.b  #0xFF, %d0           /* Compare read byte with test byte (0xFF) */
    bne     uart_fail            /* Branch if test fails */

    clr.l   %d0                  /* Clear %d0 to indicate success */
    rts

uart_fail:
    move.l  #1, %d0              /* Set failure code in %d0 */
    rts

/* Send a byte to the specified UART channel */
uart_send_byte:
    jsr     select_channel       /* Determine base address for the channel (%a0) */
    move.b  %d2, (%a0 + 3)       /* Write byte in %D2 to Transmit Holding Register (THR) */
    jsr     uart_wait_transmit   /* Use shared transmit wait routine */
    rts

/* Receive a byte from the specified UART channel */
uart_receive_byte:
    jsr     select_channel       /* Determine base address for the channel (%a0) */
    jsr     uart_wait_receive    /* Use shared receive wait routine */
    move.b  (%a0 + 3), %d2       /* Read byte from Receive Holding Register (RHR) into %D2 */
    rts

/* Send a string over UART */
uart_send_string:
    jsr     select_channel       /* Determine base address for the channel (%a0) */
uart_send_string_loop:
    move.b  (%a1)+, %d2          /* Load the next character from the string into D2 and increment A1 */
    tst.b   %d2                  /* Check if the character is null (0x00) */
    beq     uart_send_string_done /* If null, end the loop */
    jsr     uart_send_byte       /* Call uart_send_byte to transmit the character */
    bra     uart_send_string_loop /* Loop back for the next character */
uart_send_string_done:
    rts

/* Helper routine to wait for UART transmit buffer to be ready */
uart_wait_transmit:
    move.l  #50000, %d3           /* Timeout counter (adjusted for 8 MHz) */
wait_transmit_loop:
    btst    #2, (%a0 + 1)         /* Check if TX Ready (Bit 2 of SRA) */
    bne     wait_transmit_done   /* If ready, continue */
    subq.l  #1, %d3              /* Decrement timeout counter */
    bne     wait_transmit_loop   /* Loop if counter > 0 */
    bra     uart_fail            /* If timeout reached, branch to error handler */
wait_transmit_done:
    rts

/* Helper routine to wait for UART receive buffer to have data */
uart_wait_receive:
    move.l  #50000, %d3           /* Timeout counter (adjusted for 8 MHz) */
wait_receive_loop:
    btst    #0, (%a0 + 1)         /* Check if RX Ready (Bit 0 of SRA) */
    bne     wait_receive_done    /* If data received, continue */
    subq.l  #1, %d3              /* Decrement timeout counter */
    bne     wait_receive_loop    /* Loop if counter > 0 */
    bra     uart_fail            /* If timeout reached, branch to error handler */
wait_receive_done:
    rts
