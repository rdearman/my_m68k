SECTIONS
{
    . = 0x00000000;   /* Start address of ROM */

    .text : {
        LONG(0x00200000)   /* Initial stack pointer */
        LONG(0x00000008)   /* Entry point address */
        *(.text)           /* Place all .text sections here */
    }
    .data : {
        *(.data)           /* Place all .data sections here */
    }
    .bss : {
        *(.bss)            /* Place all .bss sections here */
    }
}
