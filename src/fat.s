.include "config.s"
.section .text

    /* FAT32 Boot Sector Parsing and BPB (BIOS Parameter Block) */
    .global FAT32_Init, FAT32_ReadFATEntry, FAT32_GetClusterChain, FAT32_WriteFATEntry, FAT32_FindFreeCluster

    /* Define offsets within the boot sector for BPB fields */
    .equ BPB_BytsPerSec_Offset, 0x0B   /* Offset for bytes per sector */
    .equ BPB_SecPerClus_Offset, 0x0D   /* Offset for sectors per cluster */
    .equ BPB_RsvdSecCnt_Offset, 0x0E   /* Offset for reserved sector count */
    .equ BPB_NumFATs_Offset, 0x10      /* Offset for number of FATs */
    .equ BPB_FATSz32_Offset, 0x24      /* Offset for FAT size (FAT32) */
    
    /* FAT Table Management Offsets */
    .equ FAT_ENTRY_SIZE, 4                /* FAT32 entries are 4 bytes */
    .equ FAT_CLUSTER_MASK, 0x0FFFFFFF     /* Mask to extract cluster number */
    .equ FAT_END_OF_CHAIN, 0x0FFFFFF8     /* End of chain marker for FAT32 */

    /* Variables set during initialisation */
FAT_StartSector: .space 4                 /* FAT start sector (calculated in FAT32_Init) */
SecPerClus: .space 1                       /* Sectors per cluster */

    /* Define BPB fields for use in the FAT32 structure */
    .bss
BPB_BytsPerSec: .space 2   /* Bytes per sector */
BPB_SecPerClus: .space 1   /* Sectors per cluster */
BPB_RsvdSecCnt: .space 2   /* Reserved sectors count */
BPB_NumFATs: .space 1      /* Number of FATs */
BPB_FATSz32: .space 4      /* FAT size for FAT32 */

    .text
FAT32_Init:
    /* Read the boot sector (first 512 bytes) */
    move.l #0, %a0                     /* Sector 0 for boot sector */
    jsr SD_ReadSector                  /* Assumes SD_ReadSector reads into buffer at %a0 */

    /* Extract and store BPB fields */
    /* Bytes per Sector (2 bytes) */
    move.b BPB_BytsPerSec_Offset(%a0), BPB_BytsPerSec
    move.b BPB_BytsPerSec_Offset + 1(%a0), BPB_BytsPerSec + 1

    /* Sectors per Cluster (1 byte) */
    move.b BPB_SecPerClus_Offset(%a0), BPB_SecPerClus

    /* Reserved Sector Count (2 bytes) */
    move.b BPB_RsvdSecCnt_Offset(%a0), BPB_RsvdSecCnt
    move.b BPB_RsvdSecCnt_Offset + 1(%a0), BPB_RsvdSecCnt + 1

    /* Number of FATs (1 byte) */
    move.b BPB_NumFATs_Offset(%a0), BPB_NumFATs

    /* FAT Size (4 bytes) */
    move.b BPB_FATSz32_Offset(%a0), BPB_FATSz32
    move.b BPB_FATSz32_Offset + 1(%a0), BPB_FATSz32 + 1
    move.b BPB_FATSz32_Offset + 2(%a0), BPB_FATSz32 + 2
    move.b BPB_FATSz32_Offset + 3(%a0), BPB_FATSz32 + 3

    /* End of FAT32_Init function */
    rts


/* FAT32_ReadFATEntry: Reads the FAT entry for a given cluster number */
FAT32_ReadFATEntry:
    /* Input: d0 - Current cluster number */
    /* Output: d1 - Next cluster in chain, or 0x0FFFFFF8 if end of chain */
    
    /* Calculate FAT table offset for the cluster */
    move.l %d0, %d1                        /* Copy cluster number to d1 */
    lsl.l #2, %d1                          /* Multiply by 4 (FAT32 entry size) */
    add.l FAT_StartSector, %d1             /* Add to FAT start sector */

    /* Read the FAT entry */
    jsr SD_ReadSector                      /* Read the sector containing the FAT entry */
    
    /* Get the 4-byte entry from the FAT table */
    move.l (%a0, %d1), %d1                 /* Load FAT entry into d1 */
    and.l #FAT_CLUSTER_MASK, %d1           /* Mask out high bits to get cluster */
    
    rts                                     /* Return next cluster in chain */
    

/* FAT32_GetClusterChain: Reads all clusters in a file by following the chain */
FAT32_GetClusterChain:
    /* Input: d0 - Starting cluster number */
    /* Output: Sequentially returns each cluster in chain until end */

    move.l %d0, %d1                      /* Set starting cluster to d1 */
NextCluster:
    jsr FAT32_ReadFATEntry               /* Get next cluster in chain */
    
    cmp.l #FAT_END_OF_CHAIN, %d1         /* Check for end of chain */
    beq EndOfChain                       /* If end of chain, exit */

    /* Process current cluster here (e.g., read data) */
    jsr ProcessCluster                   /* Placeholder for reading/writing data */

    bra NextCluster                      /* Loop to get next cluster */

EndOfChain:
    rts                                   /* Return at end of cluster chain */

/* FAT32_WriteFATEntry: Updates a FAT entry to point to the next cluster */
FAT32_WriteFATEntry:
    /* Input: d0 - Current cluster number, d1 - Next cluster number */
    
    /* Calculate FAT table offset */
    move.l %d0, %d2
    lsl.l #2, %d2                         /* Multiply by 4 (FAT32 entry size) */
    add.l FAT_StartSector, %d2            /* Add to FAT start sector */

    /* Update FAT entry with next cluster */
    move.l %d1, (%a0, %d2)                /* Store next cluster in FAT table */

    /* Optionally write back to SD card */
    jsr SD_WriteSector

    rts

/* FAT32_FindFreeCluster: Finds a free cluster by scanning the FAT */
FAT32_FindFreeCluster:
    /* Output: d0 - Free cluster number, or error if none found */

    move.l #2, %d0                        /* Start search from cluster 2 */
FindFreeLoop:
    jsr FAT32_ReadFATEntry                /* Read FAT entry for cluster in d0 */
    cmp.l #0, %d1                         /* Check if cluster is free (0) */
    beq FreeClusterFound

    addq.l #1, %d0                        /* Move to the next cluster */
    bra FindFreeLoop

FreeClusterFound:
    rts                                    /* Return free cluster number in d0 */
