.include "config.s"

	.section .data
	/* Vector Table Section */
    .section .vectors, "a"          /* Vector table section */
    .org 0x00000000                 /* Start at address 0 */

	/* Reset Vectors */
    .long STACK_TOP_ADDR                /* Vector 0: Initial Stack Pointer (SSP) */
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

    .long 0                         /* Address error exception vector (optional, unused here) */
    .rept (0x400 / 4 - 16)
    .long _catchall
    .endr       /* Zero out unused vectors */


	/* --- Text Section --- */
    .section .text                  /* Code section */
    .global _init_start                  /* Declare _start as global */
    .global _catchall
    .global _address_error

	/* ========== Default Interrupt Handlers ========== */

_bus_error:
	move.l (%sp)+, %d0             /* Pop faulting address from stack */
	move.l %d0, 0x00FFFF10         /* Save it to a known memory location for debugging */

	/* Retrieve and Save Status Register */
	move.w (%sp)+, %d1             /* Pop status register from stack */
	move.w %d1, 0x00FFFF14         /* Save it to another known memory location */

	/* Debug Halt */
	trap #0                        /* Trigger a breakpoint (optional) */
	bra .                          /* Loop forever (halt the CPU) */

_address_error:
	/* Save Registers */
	move.l  (%sp)+, %d0             /* Faulting address */
	move.l  %d0, 0x00FFFF00         /* Store faulting address at a known location */
	move.w  (%sp)+, %d1             /* Status register */
	move.w  %d1, 0x00FFFF04         /* Store status register */

	/* Infinite Loop for Debugging */
	trap    #0                      /* Trigger a breakpoint (optional) */
	bra     .                       /* Loop forever */

_illegal_inst:
	bra _catchall

_zero_divide:
	bra _catchall

_chk_inst:
	bra _catchall

_trapcc:
	bra _catchall

_priv_violation:
	bra _catchall

_trace:
	bra _catchall

_line_1010:
	bra _catchall

_line_1111:
	bra _catchall

_reserved:
	bra _catchall

_coproto_violation:
	bra _catchall

_format_error:
	bra _catchall

_uninit_vector:
	bra _catchall

_spurious_interrupt:
	bra _catchall

_level1_autovector:
	bra _catchall

_level2_autovector:
	bra _catchall

_level3_autovector:
	bra _catchall

_level4_autovector:
	bra _catchall

_level5_autovector:
	bra _catchall

_level6_autovector:
	bra _catchall

_level7_autovector:
	bra _catchall

_fpu_error:
	bra _catchall

_mmu_error:
	bra _catchall

_trap:
	bra _catchall

_user_int:
	bra _catchall

_catchall:
	/* HALT */
	move.l #0x2700, %d0  /* Load interrupt mask to disable all interrupts */
	move.w %d0, %sr      /* Set the status register to disable interrupts */
	stop #0x2700         /* Halt the CPU with interrupts disabled */


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
.extern uart_check, uart_init, uart_send_byte, select_channel

	/* Conditional entry for monitor */
MONITOR_ENTRY:
.if MONITOR_ENTRY != 0
	jmp MONITOR_ENTRY
.else
	jmp _idle_loop
.endif

	/* Bootloader entry point */
_start:
	/* Initialize the stack pointer */
	move.l #STACK_TOP_ADDR, %sp  /* Set up stack pointer to top of RAM */
	
	jsr     uart_init                  /* Call uart_init using jsr */
	
    move.b  #0, %d1              /* Select Channel A */	
	jsr     select_channel        /* Set base address for Channel A/0 or B/1 in %a0 */
wait_for_q:	
	jsr     uart_receive_byte    /* Wait for and retrieve a byte */
    move.b  %d0, %d2            /* Store the received character in %d2 */
    cmpi.b  #'q', %d2           /* Compare received character with 'q' */
    bne     wait_for_q          /* Loop until the received character is 'q' */

	
    /* At this point, %d2 contains 'q', and the loop exits */

    /* Additional processing for received_char can be added here */

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


	
