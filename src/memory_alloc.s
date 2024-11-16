.include "config.s"
.section .text
.global malloc, free, memory_init, pool_alloc

	/* Define initial memory heap pointers */
.data
heap_start:       .long 0x200000       /* Start of heap in RAM */
heap_end:         .long 0x210000       /* End of heap */
heap_pointer:     .long 0x200000       /* Current position in heap */

pool_start:       .long 0x210000       /* Start of memory pool */
pool_end:         .long 0x214000       /* End of memory pool */
pool_block_size:  .long 32             /* Size of each block in the pool */
pool_free_list:   .long 0x210000       /* Tracks free blocks in pool */

	/* Memory Initialisation Routine */
memory_init:
	move.l heap_start, heap_pointer    /* Reset heap pointer to start of heap */
	move.l pool_start, pool_free_list  /* Initialize pool free list to pool start */
	rts

	/* malloc: Allocates a block of memory of a given size with boundary protection */
malloc:
	move.l heap_pointer, %a0           /* Load current heap pointer */
	add.l  %d0, %a0                    /* Add requested size to pointer */
	cmp.l  heap_end, %a0               /* Check if allocation exceeds heap end */
	bhs    malloc_fail                 /* If exceeds, fail */

	/* Boundary protection check - ensure allocation does not overlap with critical regions */
	cmp.l  #STACK_TOP_ADDR, %a0
	bls    malloc_fail                 /* Fail if within stack region */

	move.l %a0, heap_pointer           /* Update heap pointer */
	sub.l  %d0, %a0                    /* Set return address to original pointer */
	rts

malloc_fail:
	move.l #0x0, %a0                   /* Return NULL */
	rts

	/* Pool Allocator: Allocates fixed-size blocks from the memory pool */
pool_alloc:
	move.l pool_free_list, %a0         /* Get the next free block */
	cmp.l pool_end, %a0                /* Check if out of pool memory */
	bhs    pool_alloc_fail             /* If out, fail */

	/* Update pool free list to next block in pool */
	add.l  pool_block_size, pool_free_list

	/* Return address of allocated block */
	rts

pool_alloc_fail:
	move.l #0x0, %a0                   /* Return NULL if no blocks left */
	rts

	/* free: Placeholder for releasing memory - Not yet implemented */
free:
	rts
