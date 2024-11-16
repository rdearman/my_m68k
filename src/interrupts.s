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
	movem.l %d0-%d7/%a0-%a6, -(%sp)  /* Preserve registers */
	cmpi.b  #1, %d0                  /* Check if UART interrupt (priority 1) */
	beq handle_uart_interrupt
	cmpi.b  #2, %d0                  /* Check if SPI interrupt (priority 2) */
	beq handle_spi_interrupt
	cmpi.b  #3, %d0                  /* Check if I2C interrupt (priority 3) */
	beq handle_i2c_interrupt
	movem.l (%sp)+, %d0-%d7/%a0-%a6  /* Restore registers */
	rte                              /* Return if no known interrupt */

handle_uart_interrupt:
	jsr uart_isr                     /* Call UART handler */
	bra end_interrupt

handle_spi_interrupt:
	jsr spi_isr                      /* Call SPI handler */
	bra end_interrupt

handle_i2c_interrupt:
	jsr i2c_isr                      /* Call I2C handler */

end_interrupt:
	movem.l (%sp)+, %d0-%d7/%a0-%a6  /* Restore registers */
	rte                              /* Return from interrupt */

.section .vectors, "ax"              /* Define the vector section */

.org 0x000000                        /* Set the origin to the start of the vector table */

	/* Reset Vectors */
    .long _initial_sp                /* Vector 0: Initial Stack Pointer (SSP) */
    .long _start                     /* Vector 1: Initial Program Counter (PC) */

	/* Exception Vectors */
    .long _bus_error                 /* Vector 2: Bus error */
    .long _address_error             /* Vector 3: Address error */
    .long _illegal_inst              /* Vector 4: Illegal instruction / BKPT */
    .long _zero_divide               /* Vector 5: Zero divide */
    .long _chk_inst                  /* Vector 6: CHK, CHK2 instruction */
    .long _trapcc                    /* Vector 7: cpTRAPcc, TRAPcc, TRAPV instructions */
    .long _priv_violation            /* Vector 8: Privilege violation */
    .long _trace                     /* Vector 9: Trace */
    .long _line_1010                 /* Vector 10: Unimplemented instruction (line 1010) */
    .long _line_1111                 /* Vector 11: Unimplemented instruction (line 1111) */
    .long _reserved                  /* Vector 12: Reserved */
    .long _coproto_violation         /* Vector 13: Coprocessor protocol violation */
    .long _format_error              /* Vector 14: Format error */
    .long _uninit_vector             /* Vector 15: Uninitialised interrupt vector */

	/* Level 1 - Level 7 Autovectors */
    .long _spurious_interrupt        /* Vector 24: Spurious interrupt */
    .long _level1_autovector         /* Vector 25: Level 1 autovector */
    .long _level2_autovector         /* Vector 26: Level 2 autovector */
    .long _level3_autovector         /* Vector 27: Level 3 autovector */
    .long _level4_autovector         /* Vector 28: Level 4 autovector */
    .long _level5_autovector         /* Vector 29: Level 5 autovector */
    .long _level6_autovector         /* Vector 30: Level 6 autovector */
    .long _level7_autovector         /* Vector 31: Level 7 autovector */

	/* TRAP #0-15 Instructions */
    .rept 16                         /* Repeat 16 times for TRAP vectors 32-47 */
        .long _trap                  /* Trap handler */
    .endr

	/* Floating-Point Coprocessor Errors (48-54) */
    .rept 7
        .long _fpu_error             /* FPU error handler */
    .endr

	/* Memory Management Errors (56-58) */
    .long _mmu_error                 /* Vector 56: MMU error */
    .long _mmu_error                 /* Vector 57: MMU error */
    .long _mmu_error                 /* Vector 58: MMU error */

	/* User Device Interrupts */
    .org 0x00000100                  /* Start user device interrupt vector area */
    .rept 192                        /* User device vectors (64-255) */
        .long _user_int              /* Placeholder handler for user interrupts */
    .endr

	/* ========== Default Interrupt Handlers ========== */

_init_start:
	jmp main                         /* Main entry point */

_initial_sp:
    .long 0x200000                   /* Top of RAM stack pointer */

_bus_error:
	rte

_address_error:
	rte

_illegal_inst:
	rte

_zero_divide:
	rte

_chk_inst:
	rte

_trapcc:
	rte

_priv_violation:
	rte

_trace:
	rte

_line_1010:
	rte

_line_1111:
	rte

_reserved:
	rte

_coproto_violation:
	rte

_format_error:
	rte

_uninit_vector:
	rte

_spurious_interrupt:
	rte

_level1_autovector:
	rte

_level2_autovector:
	rte

_level3_autovector:
	rte

_level4_autovector:
	rte

_level5_autovector:
	rte

_level6_autovector:
	rte

_level7_autovector:
	rte

_fpu_error:
	rte

_mmu_error:
	rte

_trap:
	rte

_user_int:
	rte
