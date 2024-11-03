.section .text
.global malloc, free, memory_init

/* Define initial memory heap pointers */
.data
heap_start:  .long 0x200000    /* Start of heap in RAM */
heap_end:    .long 0x210000    /* End of heap */
heap_pointer: .long 0x200000   /* Current position in heap */

/* Memory Initialisation Routine */
memory_init:
    move.l heap_start, heap_pointer  /* Reset heap pointer to start */
    rts

/* malloc: Allocates a block of memory of a given size */
malloc:
    move.l heap_pointer, %a0        /* Load current heap pointer */
    add.l  %d0, %a0                 /* Add requested size */
    cmp.l  heap_end, %a0            /* Check if exceeds heap end */
    bhs    malloc_fail              /* If exceeds, fail */
    move.l %a0, heap_pointer        /* Update heap pointer */
    sub.l  %d0, %a0                 /* Set return address to original pointer */
    rts

malloc_fail:
    move.l #0x0, %a0                /* Return NULL */
    rts

/* free: Releases memory - Placeholder as 68000 has no dynamic memory management */
free:
    rts
