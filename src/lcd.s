.include "config.s"
.section .text
.global lcd_init, lcd_send_command, lcd_send_data, lcd_set_cursor, lcd_clear_display, lcd_check
.extern spi_transmit_byte

	SPI_DATA_REG = 0xC00002    /* Example address, update as needed */


	/* Macro Definitions */
    .macro SET_MOSI_HIGH
	bset    #0, 0xC00002         /* Set PB0 (MOSI) high */
    .endm

    .macro SET_MOSI_LOW
	bclr    #0, 0xC00002         /* Clear PB0 (MOSI) low */
    .endm

    .macro TOGGLE_SCK
	bset    #2, 0xC00002         /* Set PB2 (SCK) high */
	nop                           /* Delay */
	bclr    #2, 0xC00002         /* Set PB2 (SCK) low */
    .endm

	/* LCD Initialisation */
lcd_init:
	move.b #0x01, %d1                  /* Example initialisation command */
	jsr spi_select_device               /* Select LCD via CS */
	jsr lcd_send_command                /* Send initialisation command */
	jsr spi_deselect_device             /* Deselect LCD */

	/* Perform a test to verify initialisation was successful */
	move.b #0xAA, %d1                   /* Dummy test command */
	jsr lcd_send_command
	tst.b %d0                           /* Check return code */
	bne lcd_init_fail
	clr.b %d0                           /* Success return code */
	rts

lcd_check:
	clr.b   %d0                  /* Return success FUNCTION TBD */
	rts


lcd_init_fail:
	move.b #1, %d0                      /* Set error code for failure */
	rts

	/* Send Command to LCD */
lcd_send_command:
	move.b %d1, %d2                     /* Copy command into %d2 for use */
	jsr spi_select_device               /* Select LCD via CS */

	SET_MOSI_HIGH                       /* Set data line for MOSI */
	move.b %d2, SPI_DATA_REG            /* Send byte to SPI data register */

	jsr spi_transmit_byte                    /* Transmit data over SPI */
	tst.b %d0                           /* Check for successful transmission */
	jsr spi_deselect_device             /* Deselect LCD */
	rts

	/* Send Data to LCD */
lcd_send_data:
	move.b %d1, %d2                     /* Copy data into %d2 */
	jsr spi_select_device               /* Select LCD via CS */

	SET_MOSI_HIGH
	move.b %d2, SPI_DATA_REG            /* Write data byte */

	jsr spi_transmit_byte                    /* Transmit data */
	tst.b %d0                           /* Check transmission status */
	jsr spi_deselect_device             /* Deselect LCD */
	rts

	/* Set LCD Cursor Position */
lcd_set_cursor:
	move.b %d1, %d2                     /* Row */
	move.b %d3, %d4                     /* Column */
	/* Command sequence to set cursor position */
	move.b #0x80, %d1                   /* Base command for setting cursor */
	or.b %d2, %d1                       /* Add row offset */
	or.b %d4, %d1                       /* Add column offset */
	jsr lcd_send_command                /* Send command to set position */
	rts

	/* Clear LCD Display */
lcd_clear_display:
	move.b #0x01, %d1                   /* Clear display command */
	jsr lcd_send_command                /* Send clear display command */
	rts
