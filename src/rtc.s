.include "config.s"
.section .text
.global rtc_init, rtc_read_time, rtc_set_time, rtc_set_alarm, rtc_get_timestamp, rtc_check
.extern i2c_start, i2c_stop, i2c_write_byte, i2c_read_byte

RTC_SECONDS_REG = 0x600010    /* Example, replace with actual address */
RTC_ALARM_MIN_REG = 0x600014  /* Example, replace with actual address */


/* Register addresses for PCF8563 RTC */
RTC_SECONDS_REG      = 0x02
RTC_MINUTES_REG      = 0x03
RTC_HOURS_REG        = 0x04
RTC_DAY_REG          = 0x05
RTC_MONTH_REG        = 0x07
RTC_YEAR_REG         = 0x08
RTC_ALARM_MIN_REG    = 0x09
RTC_ALARM_HOUR_REG   = 0x0A
	
/* RTC Initialisation with I2C Check */
rtc_init:
    jsr i2c_start                       /* Start I2C communication */
    move.b #RTC_SECONDS_REG, %d0        /* Select seconds register for a test read */
    jsr i2c_write_byte
    tst.b %d0                           /* Check for I2C write success */
    bne rtc_init_fail
    jsr i2c_read_byte
    tst.b %d0                           /* Check if read succeeded */
    bne rtc_init_fail
    jsr i2c_stop                        /* End I2C communication */
    clr.b %d0                           /* Success code */
    rts

rtc_check:
        clr.b   %d0                  /* Return success FUNCTION TBD */
        rts
	
rtc_init_fail:
    move.b #1, %d0                      /* Failure code */
    rts

/* Read Time from RTC: Output seconds, minutes, hours, day, month, year */
rtc_read_time:
    jsr i2c_start
    move.b #RTC_SECONDS_REG, %d0        /* Start reading from seconds register */
    jsr i2c_write_byte
    tst.b %d0
    bne rtc_read_fail

    /* Read seconds, minutes, hours, day, month, and year in sequence */
    jsr i2c_read_byte                   /* Read seconds */
    move.b %d0, rtc_seconds
    jsr i2c_read_byte                   /* Read minutes */
    move.b %d0, rtc_minutes
    jsr i2c_read_byte                   /* Read hours */
    move.b %d0, rtc_hours
    jsr i2c_read_byte                   /* Read day */
    move.b %d0, rtc_day
    jsr i2c_read_byte                   /* Read month */
    move.b %d0, rtc_month
    jsr i2c_read_byte                   /* Read year */
    move.b %d0, rtc_year

    jsr i2c_stop                        /* End I2C communication */
    clr.b %d0                           /* Success */
    rts

rtc_read_fail:
    jsr i2c_stop
    move.b #1, %d0                      /* Failure */
    rts

/* Set Time to RTC: Inputs seconds, minutes, hours, day, month, year in registers */
rtc_set_time:
    jsr i2c_start
    move.b #RTC_SECONDS_REG, %d0        /* Start writing at seconds register */
    jsr i2c_write_byte
    tst.b %d0
    bne rtc_set_fail

    /* Write seconds, minutes, hours, day, month, and year */
    move.b rtc_seconds, %d0
    jsr i2c_write_byte
    move.b rtc_minutes, %d0
    jsr i2c_write_byte
    move.b rtc_hours, %d0
    jsr i2c_write_byte
    move.b rtc_day, %d0
    jsr i2c_write_byte
    move.b rtc_month, %d0
    jsr i2c_write_byte
    move.b rtc_year, %d0
    jsr i2c_write_byte

    jsr i2c_stop                        /* End I2C communication */
    clr.b %d0                           /* Success */
    rts

rtc_set_fail:
    jsr i2c_stop
    move.b #1, %d0                      /* Failure */
    rts

/* Set Alarm Time on RTC: Inputs alarm minute and hour */
rtc_set_alarm:
    jsr i2c_start
    move.b #RTC_ALARM_MIN_REG, %d0      /* Start writing at alarm minute register */
    jsr i2c_write_byte
    tst.b %d0
    bne rtc_alarm_fail

    /* Set alarm minute and hour */
    move.b rtc_alarm_minute, %d0
    jsr i2c_write_byte
    move.b rtc_alarm_hour, %d0
    jsr i2c_write_byte

    jsr i2c_stop                        /* End I2C communication */
    clr.b %d0                           /* Success */
    rts

rtc_alarm_fail:
    jsr i2c_stop
    move.b #1, %d0                      /* Failure */
    rts

/* Get Formatted Timestamp */
rtc_get_timestamp:
    /* Format timestamp as [YY-MM-DD HH:MM:SS] */
    move.b rtc_year, %d0
    jsr format_two_digit
    move.b rtc_month, %d0
    jsr format_two_digit
    move.b rtc_day, %d0
    jsr format_two_digit
    move.b rtc_hours, %d0
    jsr format_two_digit
    move.b rtc_minutes, %d0
    jsr format_two_digit
    move.b rtc_seconds, %d0
    jsr format_two_digit
    rts

/* Helper routine to format single byte into two-digit ASCII */
format_two_digit:
    and.b #0x0F, %d0                   /* Mask upper nibble */
    add.b #'0', %d0                    /* Convert to ASCII */
    rts

/* Temporary variables */
rtc_seconds: .byte 0
rtc_minutes: .byte 0
rtc_hours:   .byte 0
rtc_day:     .byte 0
rtc_month:   .byte 0
rtc_year:    .byte 0
rtc_alarm_minute: .byte 0
rtc_alarm_hour:   .byte 0
