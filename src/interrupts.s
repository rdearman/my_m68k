    .section .text
    .global init_interrupt_vectors, central_interrupt_handler
    .global enable_interrupts, disable_interrupts
    .extern uart_isr, spi_isr, i2c_isr  /* External ISRs for specific devices */

    /* Enable global interrupts */
enable_interrupts:
    move.w  #0x2000, %sr            /* Clear interrupt mask */
    rts

    /* Disable global interrupts */
disable_interrupts:
    move.w  #0x2700, %sr            /* Set interrupt mask to disable interrupts */
    rts

    /* Initialise Interrupt Vector Table */
init_interrupt_vectors:
    lea vector_table, %a0          /* Base address of the vector table */
    move.l  #central_interrupt_handler, (%a0) /* Set central interrupt handler */
    addq.l  #4, %a0
    move.l  #uart_isr, (%a0)       /* UART interrupt vector */
    addq.l  #4, %a0
    move.l  #spi_isr, (%a0)        /* SPI interrupt vector */
    addq.l  #4, %a0
    move.l  #i2c_isr, (%a0)        /* I2C interrupt vector */
    rts

    /* Central Interrupt Handler */
central_interrupt_handler:
    /* Preserve registers to maintain system state */
    movem.l %d0-%d7/%a0-%a6, -(%sp)
    cmpi.b  #1, %d0                /* Check if UART interrupt (priority 1) */
    beq handle_uart_interrupt
    cmpi.b  #2, %d0                /* Check if SPI interrupt (priority 2) */
    beq handle_spi_interrupt
    cmpi.b  #3, %d0                /* Check if I2C interrupt (priority 3) */
    beq handle_i2c_interrupt

    /* Restore registers and return if no known interrupt */
    movem.l (%sp)+, %d0-%d7/%a0-%a6
    rte

handle_uart_interrupt:
    jsr uart_isr                   /* Call UART handler */
    bra end_interrupt

handle_spi_interrupt:
    jsr spi_isr                    /* Call SPI handler */
    bra end_interrupt

handle_i2c_interrupt:
    jsr i2c_isr                    /* Call I2C handler */

end_interrupt:
    /* Restore registers and return from interrupt */
    movem.l (%sp)+, %d0-%d7/%a0-%a6
    rte

    /* Vector Table */
vector_table:
    .long 0x00000000               /* Default reset vector */
    .long central_interrupt_handler /* Main interrupt handler for vectors */
    .long uart_isr                 /* UART interrupt vector */
    .long spi_isr                  /* SPI interrupt vector */
    .long i2c_isr                  /* I2C interrupt vector */
