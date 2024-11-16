.include "config.s"
.section .text
.global uart_init, uart_send_byte, uart_receive_byte, uart_check, set_baud_rate, uart_send_string

/* Base addresses for each channel */
.equ UART_BASE, 0x40000000
.equ UART_CHANNEL_A_BASE, UART_BASE       /* Channel A base address */
.equ UART_CHANNEL_B_BASE, UART_BASE + 8   /* Channel B base address (offset 0x08) */

/* Register offsets from the base address */
.equ UART_MR,  0x00        /* Mode Register (MR1A/MR2A) */
.equ UART_SR,  0x01        /* Status Register (SRA) */
.equ UART_CR,  0x02        /* Command Register (CRA) */
.equ UART_RHR, 0x03        /* Receive Holding Register (RHR) */
.equ UART_THR, 0x03        /* Transmit Holding Register (THR) */
.equ UART_CSR, 0x04        /* Clock Select Register (CSRA) */
.equ UART_ACR, 0x05        /* Auxiliary Control Register (ACR) */
.equ UART_IMR, 0x07        /* Interrupt Mask Register (IMR) */

/* Compute channel base address */
select_channel:
    cmpi.b  #0, %d1               /* Check if %d1 (channel flag) is 0 (Channel A) */
    beq    .use_channel_a
    movea.l #UART_CHANNEL_B_BASE, %a0 /* Use Channel B */
    rts
.use_channel_a:
    movea.l #UART_CHANNEL_A_BASE, %a0 /* Use Channel A */
    rts

/* Delay subroutine */
uart_delay:
    move.l  #100, %d0            /* Adjust the loop counter based on timing requirements */
delay_loop:
    subq.l  #1, %d0
    bne     delay_loop
    rts

/* UART Initialisation Routine */
uart_init:
    /* Initialise Channel A */
    move.b  #0, %d1              /* Select Channel A */
    jsr     select_channel
    move.b  #0x20, (%a0 + UART_CR) /* Reset MR pointer */
    jsr     uart_delay           /* Delay for MR pointer reset */
    move.b  #0x13, (%a0 + UART_MR) /* Configure MR1A: 8 Data Bits, No Parity */
    jsr     uart_delay           /* Delay for MR1A */
    move.b  #0x07, (%a0 + UART_MR) /* Configure MR2A: 1 Stop Bit, Normal Mode */
    jsr     uart_delay           /* Delay for MR2A */
    move.b  #0xC0, (%a0 + UART_CSR) /* Set baud rate to 19.2 kbps */
    jsr     uart_delay           /* Delay for baud rate configuration */
    move.b  #0x80, (%a0 + UART_ACR) /* Enable Baud Rate Generator */
    jsr     uart_delay           /* Delay for ACR */
    move.b  #0x05, (%a0 + UART_CR) /* Enable Transmitter and Receiver */
    jsr     uart_delay           /* Delay for enabling TX/RX */
    move.b  #0x00, (%a0 + UART_IMR) /* Disable all interrupts */
    jsr     uart_delay           /* Delay for IMR */

    /* Initialise Channel B */
    move.b  #1, %d1              /* Select Channel B */
    jsr     select_channel
    move.b  #0x20, (%a0 + UART_CR) /* Reset MR pointer */
    jsr     uart_delay           /* Delay for MR pointer reset */
    move.b  #0x13, (%a0 + UART_MR) /* Configure MR1A: 8 Data Bits, No Parity */
    jsr     uart_delay           /* Delay for MR1A */
    move.b  #0x07, (%a0 + UART_MR) /* Configure MR2A: 1 Stop Bit, Normal Mode */
    jsr     uart_delay           /* Delay for MR2A */
    move.b  #0xC0, (%a0 + UART_CSR) /* Set baud rate to 19.2 kbps */
    jsr     uart_delay           /* Delay for baud rate configuration */
    move.b  #0x80, (%a0 + UART_ACR) /* Enable Baud Rate Generator */
    jsr     uart_delay           /* Delay for ACR */
    move.b  #0x05, (%a0 + UART_CR) /* Enable Transmitter and Receiver */
    jsr     uart_delay           /* Delay for enabling TX/RX */
    move.b  #0x00, (%a0 + UART_IMR) /* Disable all interrupts */
    jsr     uart_delay           /* Delay for IMR */
    rts

/* UART Self-Check Routine */
uart_check:
    jsr     select_channel       /* Determine base address for the channel (%a0) */
    move.b  #0xFF, (%a0 + UART_THR) /* Write a test byte (0xFF) to THR */
    jsr     uart_wait_transmit   /* Wait until transmit buffer is ready */

    jsr     uart_wait_receive    /* Wait until receive buffer has data */
    move.b  (%a0 + UART_RHR), %d0 /* Read received byte into %d0 */
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
    move.b  %d2, (%a0 + UART_THR) /* Write byte in %D2 to THR */
    jsr     uart_wait_transmit   /* Use shared transmit wait routine */
    rts

/* Receive a byte from the specified UART channel */
uart_receive_byte:
    jsr     select_channel       /* Determine base address for the channel (%a0) */
    jsr     uart_wait_receive    /* Use shared receive wait routine */
    move.b  (%a0 + UART_RHR), %d2 /* Read byte from RHR into %D2 */
    rts

/* Send a string over UART */
uart_send_string:
    movea.l %a0, %a1             /* Load the address of the string into A1 */
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
    btst    #2, (%a0 + UART_SR)   /* Check if TX Ready (Bit 2 of SRA) */
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
    btst    #0, (%a0 + UART_SR)   /* Check if RX Ready (Bit 0 of SRA) */
    bne     wait_receive_done    /* If data received, continue */
    subq.l  #1, %d3              /* Decrement timeout counter */
    bne     wait_receive_loop    /* Loop if counter > 0 */
    bra     uart_fail            /* If timeout reached, branch to error handler */
wait_receive_done:
    rts
