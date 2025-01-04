/* Motorola 68000 Linker Script */

/* Define memory regions */
MEMORY
{
    rom (rx) : ORIGIN = 0x00000000, LENGTH = 4M   /* ROM: 4MB (0x00000000 - 0x003FFFFF) */
    ram (rw) : ORIGIN = 0x00400000, LENGTH = 4M   /* RAM: 4MB (0x00400000 - 0x007FFFFF) */

    /* MMIO regions */
    gpio (rw) : ORIGIN = 0x00800000, LENGTH = 1M   /* GPIO: 1MB (0x00800000 - 0x008FFFFF) */
    viaa (rw) : ORIGIN = 0x00900000, LENGTH = 1M   /* VIA Chip A: 1MB (0x00900000 - 0x009FFFFF) */
    viab (rw) : ORIGIN = 0x00A00000, LENGTH = 1M   /* VIA Chip B: 1MB (0x00A00000 - 0x00AFFFFF) */
    uart (rw) : ORIGIN = 0x00B00000, LENGTH = 1M  /* UART: 64KB (0x00B00000 - 0x00B0FFFF) */

    /* Add additional MMIO regions as needed up to 0x00F00000 */
}


/* Define sections */
SECTIONS
{
    /* Place .text in ROM */
    .text ALIGN(4) : {
        *(.text)
    } > rom

    /* Place .data in RAM */
    .data ALIGN(4) : {
        __data_start = .;
        *(.data)
        __data_end = .;
    } > rom

    /* Place .bss in RAM */
    .bss ALIGN(4) : {
        __bss_start = .;
        *(.bss)
        *(COMMON)
        __bss_end = .;
    } > rom

    /* Allocate stack at the top of RAM */
    .stack ALIGN(4) : {
        __stack_top = ORIGIN(ram) + LENGTH(ram);  /* Start at the top of RAM */
        . = __stack_top - 0x1000;                 /* Allocate 4KB for the stack */
        __stack_bottom = .;                       /* Stack bottom */
    } > ram
}
