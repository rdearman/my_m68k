	/* VIA Initialisation Code */
.global via_init
via_init:
	/* Configure Data Direction for Port B */
	move.b #0x3F, VIA_DDRB                /* Set PB0-PB5 as outputs for SPI (PB0-PB2), I2C (PB4-PB5) */
	move.b VIA_DDRB, %d0                  /* Check if the configuration succeeded */
	cmp.b #0x3F, %d0
	bne via_init_fail                     /* Branch if Data Direction Register B was not set correctly */

	/* Configure Data Direction for Port A */
	move.b #0x00, VIA_DDRA                /* Set Port A as input by default */
	move.b VIA_DDRA, %d0
	cmp.b #0x00, %d0
	bne via_init_fail                     /* Branch if Data Direction Register A was not set correctly */

	/* Set up the Auxiliary Control Register (ACR) for timer and control functionality */
	move.b #0x80, VIA_ACR                 /* Configure Timer 1 in free-running mode for SPI clock generation */
	move.b VIA_ACR, %d0
	cmp.b #0x80, %d0
	bne via_init_fail                     /* Branch if ACR was not set correctly */

	#ifdef QEMU
	/* No additional Timer 2 setup for QEMU */
	#else
	move.b #0x40, VIA_ACR                 /* Set Timer 2 for square wave generation on PB6 for UART clock */
	move.b VIA_ACR, %d0
	cmp.b #0x40, %d0
	bne via_init_fail                     /* Branch if ACR update failed */

	/* Configure Timer 2 for UART clock generation using UART_BAUD_RATE */
	move.l #CLOCK_FREQ, %d0               /* System clock frequency (e.g., 8 MHz) */
	move.l #UART_BAUD_RATE, %d1           /* Load UART baud rate (e.g., 9600) */
	lsl.l #1, %d1                         /* Multiply baud rate by 2 */
	divu %d1, %d0                         /* Divide system clock by (2 * baud rate) */
	subi.l #1, %d0                        /* Subtract 1 from result */
	move.w %d0, VIA_T2C_L                 /* Load Timer 2 counter with calculated value */
	#endif

	/* Configure Peripheral Control Register (PCR) for handshake and interrupt options */
	move.b #0x1C, VIA_PCR                 /* Set PCR for handshaking on Port B */
	move.b VIA_PCR, %d0
	cmp.b #0x1C, %d0
	bne via_init_fail                     /* Branch if PCR setup failed */

	/* Enable interrupts for SPI and I2C operations */
	move.b #0xA0, VIA_IER                 /* Enable interrupt for CA1 and CA2 (I2C and SPI conditions) */
	move.b VIA_IER, %d0
	cmp.b #0xA0, %d0
	bne via_init_fail                     /* Branch if IER setup failed */

	/* Set initial output values on Port B */
	move.b #0x30, VIA_ORB                 /* Set PB4 (SCL) and PB5 (SDA) as outputs for I2C, PB0-PB2 as SPI */
	move.b VIA_ORB, %d0
	cmp.b #0x30, %d0
	bne via_init_fail                     /* Branch if ORB setup failed */

	/* If all steps succeeded, return success */
	move.b #ERR_SUCCESS, %d0              /* Set return code to indicate success */
	rts

via_init_fail:
	/* If any step failed, return initialisation failure code */
	move.b #ERR_INITIALISATION_FAIL, %d0  /* Return code for general initialisation failure */
	jsr report_error                      /* Call centralised error reporting function if implemented */
	rts
