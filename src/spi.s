.include "config.s"
.section .text
.global spi_init, spi_select_device, spi_deselect_device, spi_transmit_byte, spi_receive_byte
.global spi_transfer_byte, spi_check
.extern report_error

	/* Macro Definitions */
.macro SET_MOSI_HIGH
	bset    #0, SPI_BASE_ADDR         /* Set PB0 (MOSI) high */
.endm

.macro SET_MOSI_LOW
	bclr    #0, SPI_BASE_ADDR         /* Clear PB0 (MOSI) low */
.endm

.macro TOGGLE_SCK
	bset    #2, SPI_BASE_ADDR         /* Set PB2 (SCK) high */
	nop                               /* Delay */
	bclr    #2, SPI_BASE_ADDR         /* Set PB2 (SCK) low */
.endm

	/* Initialise SPI */
spi_init:
	move.l  #SPI_BASE_ADDR, %a0       /* DDRB address for VIA */
	move.b  #0x07, (%a0)              /* Set PB0 (MOSI), PB1 (MISO), PB2 (SCK) as outputs */

	move.b  #0x00, %d0                /* Perform a dummy transmit to check init */
	jsr     spi_transmit_byte
	tst.b   %d0                       /* Check status code from transmission */
	bne     spi_init_fail

	move.b  #ERR_SUCCESS, %d0         /* Return success */
	rts

spi_init_fail:
	move.b  #ERR_SPI_INIT_FAIL, %d0   /* Return failure code */
	jsr report_error                  /* Log the initialisation failure */
	rts

	/* Select an SPI device */
spi_select_device:
	move.l  #SPI_BASE_ADDR, %a0       /* Port A base address for CS */
	move.b  %d0, %d1                  /* Device number in %d0 */
	bclr    %d1, (%a0)                /* Clear bit to select device */
	rts

	/* Deselect an SPI device */
spi_deselect_device:
	move.l  #SPI_BASE_ADDR, %a0
	move.b  %d0, %d1
	bset    %d1, (%a0)                /* Set bit to deselect device */
	rts

	/* Transmit a single byte over SPI with timeout */
spi_transmit_byte:
	move.b  %d0, %d1                  /* Load data into %d1 */
	moveq   #8, %d2                   /* Set bit counter for 8 bits */
	move.l  #SPI_TIMEOUT_LIMIT, %d3   /* Timeout counter */

transmit_loop:
	btst    #7, %d1                   /* Check MSB of %d1 */
	bne     mosi_high
	SET_MOSI_LOW
	bra     transmit_clock

mosi_high:
	SET_MOSI_HIGH

transmit_clock:
	TOGGLE_SCK
	lsl.b   #1, %d1                   /* Shift data left */
	subq    #1, %d2                   /* Decrement bit counter */
	bne     transmit_loop             /* Continue if bits remain */

	clr.b   %d0                       /* Indicate success */
	rts

spi_transmit_timeout:
	move.b  #ERR_TIMEOUT, %d0         /* Set timeout error code */
	jsr report_error                  /* Log the timeout */
	rts

	/* Receive a single byte over SPI with timeout */
spi_receive_byte:
	clr.b   %d0                       /* Clear %d0 for received data */
	moveq   #8, %d2                   /* Set bit counter for 8 bits */
	move.l  #SPI_TIMEOUT_LIMIT, %d3   /* Timeout counter */

receive_loop:
	TOGGLE_SCK
	btst    #1, SPI_BASE_ADDR         /* Test MISO */
	bset    #0, %d0                   /* Set bit in %d0 if MISO is high */
	lsl.b   #1, %d0                   /* Shift received data left */
	subq    #1, %d2                   /* Decrement bit counter */
	bne     receive_loop              /* Continue until all bits are received */

	clr.b   %d0                       /* Indicate success */
	rts

spi_receive_timeout:
	move.b  #ERR_TIMEOUT, %d0         /* Set timeout error code */
	jsr report_error                  /* Log the timeout */
	rts

	/* Full-duplex SPI transfer (simultaneously send and receive a byte) */
spi_transfer_byte:
	move.b  %d0, %d1                  /* Load data to transmit into %d1 */
	clr.b   %d0                       /* Clear %d0 for receiving data */
	moveq   #8, %d2                   /* Set bit counter to 8 bits */

transfer_loop:
	btst    #7, %d1                   /* Check MSB of %d1 */
	bne     set_transfer_mosi_high
	SET_MOSI_LOW
	bra     transfer_clock

set_transfer_mosi_high:
	SET_MOSI_HIGH

transfer_clock:
	TOGGLE_SCK
	btst    #1, SPI_BASE_ADDR         /* Test MISO */
	bset    #0, %d0                   /* Set bit in %d0 if MISO is high */
	lsl.b   #1, %d1                   /* Shift transmit data left */
	lsl.b   #1, %d0                   /* Shift received data left */
	subq    #1, %d2                   /* Decrement bit counter */
	bne     transfer_loop             /* Continue until all bits are transferred */

	clr.b   %d0                       /* Indicate success */
	rts
