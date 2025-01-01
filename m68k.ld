/* Linker Script for Motorola 68000 */

/* Define memory regions */
MEMORY
{
    rom (rx) : ORIGIN = 0x00000000, LENGTH = 4M   /* ROM: 4MB (0x00000000 - 0x003FFFFF) */
    ram (rw) : ORIGIN = 0x00400000, LENGTH = 4M   /* RAM: 4MB (0x00400000 - 0x007FFFFF) */
}

/* Define sections */
SECTIONS
{
    /* Vector table at the start of ROM */
    .vectors 0x00000000 :
    {
        KEEP(*(.vectors))     /* Ensure vector table is not discarded */
    } > rom

    /* Code section starts after the vector table */
    .text ALIGN(0x100) :      /* Align to the next 256-byte boundary */
    {
        *(.text)              /* All .text sections */
        *(.rodata*)           /* Read-only data */
    } > rom

    /* Initialized data section in RAM (loaded from ROM) */
    .data :
    {
        *(.data)              /* All .data sections */
    } > ram AT > rom

    /* Uninitialized data (BSS) section in RAM */
    .bss :
    {
        __bss_start = .;      /* Start of BSS */
        *(.bss)               /* All .bss sections */
        *(COMMON)             /* Common sections */
        __bss_end = .;        /* End of BSS */
    } > ram

    /* Stack pointer setup */
    .stack :
    {
        _stack = ORIGIN(ram) + LENGTH(ram); /* Stack pointer at top of RAM */
    } > ram

    /* Provide symbols for startup code */
    _start = 0x00000000;       /* Entry point */
}
