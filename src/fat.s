.include "config.s"
.section .text
.global fat_init, fat_find_file, fat_read_file, fat_write_file, fat_list_directory



/* FAT Filesystem Initialisation */
fat_init:
    ; Read the boot sector of the SD card to retrieve FAT filesystem parameters
    ; Expected to configure bytes per sector, sectors per cluster, FAT count, etc.
    ; These values are crucial for calculating cluster locations.
    rts

/* Find a File by Name in the Directory */
fat_find_file:
    ; Search for a file by name in the current directory
    ; 1. Locate the directory sector.
    ; 2. Loop through entries, matching against the file name.
    ; 3. If found, store the starting cluster in a register for later access.
    rts

/* Read a File */
fat_read_file:
    ; Read file data from a specific cluster chain on the FAT filesystem
    ; 1. Use the starting cluster to locate data.
    ; 2. For each cluster, calculate the physical sector location on the SD card.
    ; 3. Copy the data into memory.
    ; 4. Follow the FAT chain to the next cluster if the file spans multiple clusters.
    rts

/* Write a File */
fat_write_file:
    ; Write data to a file, possibly extending it over new clusters if needed
    ; 1. Locate an existing file or create a new one in the directory.
    ; 2. Allocate clusters from the FAT table as required.
    ; 3. Write data into each cluster.
    ; 4. Update the directory entry with the new file size and start cluster.
    rts

/* List Files in the Current Directory */
fat_list_directory:
    ; Display or log all files and subdirectories in the current directory
    ; 1. Load directory sector.
    ; 2. Loop through each directory entry.
    ; 3. Display file names, sizes, and attributes (like subdirectories).
    rts

/* Utility Functions for Cluster Calculations and Directory Navigation */
fat_next_cluster:
    ; Follow the FAT table to retrieve the next cluster in a chain.
    ; This is necessary when a file spans multiple clusters.
    rts

fat_allocate_cluster:
    ; Locate and mark a free cluster in the FAT table for new file data.
    ; Useful when a file is being extended or created.
    rts
