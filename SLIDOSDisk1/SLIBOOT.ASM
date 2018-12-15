Name            SLIBOOT

Title           Software_labs_inc_boot

Subttl          Boot

Page 60,132

; *************************************************************************
; *                                                                       *
; *             (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Subttl          Sli_dos

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                            SLI DOS                                   |
; |                                                                      |
; |      Set up label for sliboot to jump to after reading from disk     |
; |                                                                      |
; ------------------------------------------------------------------------

Sli_dos_seg     segment at 800h

                org     00h

Slidos          label   far

Sli_dos_seg      ends

Subttl          Sli_boot

Page

Code_seg        segment public 'code'

                org   7c00h

                assume  cs:code_seg

; =========================================================================
; *                                                                       *
; *                              SLI BOOT                                 *
; *                                                                       *
; *      Boot is read into memory by the PROM interrupt 19h. It check to  *
; *    to see if SLIDOS is present on the disk. If so read in SLIDOS and  *
; *      transfers control to it. (location 800:0)                        *
; *                                                                       *
; =========================================================================

Sli_boot        proc    near

                jmp     start_sli_boot

; Data Area to be used by boot

sli_dos_name                    db     'slidos  com'

Total_no_of_sectors_to_read     db     10

No_of_sectors_to_read           db     1

Sector_size                     dw     200h

Current_track                   db     0

Current_sector                  db     8

; Boot messages

Reboot_message                  db     05h,0fh
                                db     'Sorry, this is not a MASTER '
                                db     'disk. Place the MASTER disk in '
                                db     'Drive A:.',0ffh

Strike_any_key_message          db     1bh,11h
                                db     'To continue press a key.',0ffh

Boot_failure_message            db     05h,0fh
                                db     'The disk drive is not '
                                db     'working properly. Please restart '
                                db     'the Computer. '
                                db     0ffh

Copyright_message               db     '(C)opyright 1983 Software '
                                db     'Laboratories Inc.'

Author_message                  db     'Author,Cameron L Wolff'

        Start_sli_boot:
     
                cli

; Set up segment registers and stack pointer

                mov     ax,cs
                mov     ds,ax
                mov     ax,800h
                mov     es,ax
                xor     ax,ax
                mov     ss,ax
                mov     sp,7c00h

                sti

; Reset the disk system

                xor     ax,ax
                int     13h

                jnc     check_for_sli_dos

                call    boot_failure

; Check to see if wvdos.com is the first entry in the directory

        Check_for_sli_dos:

                call    sli_dos_check

                jnc     read_sli_dos

                call    disk_reboot

; Read in wvdos.com and transfer control to it.
; Wvdos.com is a system file hence it will be loaded by an absolute
; disk address read. The number of sectors to be read are determined
; by the variable total_no_of_sectors_to_read. Boot will read consecutively
; from track 0 sector 8 until all the wvdos.com sectors are read.

        Read_sli_dos:

                xor     bx,bx              ; starting offset

; Disk read loop.

        Sli_dos_read_loop:

                mov     ah,2
                mov     al,no_of_sectors_to_read
                mov     ch,current_track
                mov     cl,current_sector
                xor     dx,dx
                int     13h

                jnc     check_if_done

                call    boot_failure       ; boot failure inform user

; Check to see if all the sectors have been read

        Check_if_done:

                cmp     total_no_of_sectors_to_read,0
                jz      sli_dos_jump

; Calculate next offset within segment 60h to read

                mov     al,no_of_sectors_to_read
                cbw
                mul     sector_size
                add     bx,ax

 ; Update disk read parameters

                mov     al,total_no_of_sectors_to_read
                cmp     total_no_of_sectors_to_read,8
                ja      more_than_full_track

                mov     no_of_sectors_to_read,al
                mov     total_no_of_sectors_to_read,0
                jmp     update_disk_info

        More_than_full_track:

                sub     al,no_of_sectors_to_read
                mov     total_no_of_sectors_to_read,al
                mov     no_of_sectors_to_read,8

        Update_disk_info:

                inc     current_track
                mov     current_sector,1
                jmp     sli_dos_read_loop

; Wvdos.com has been read in transfer control to it

        Sli_dos_jump:

                jmp     slidos

Sli_boot        endp

Subttl          Boot_failure

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                              BOOT FAILURE                            |
; |                                                                      |
; |                  Disk boot failure, disk drive failed.               |
; |                  Inform user and stay in infinite loop.              |
; |                                                                      |
; ------------------------------------------------------------------------

Boot_failure    proc    near

                mov     si,offset boot_failure_message
                call    display_message

        Infinite_loop:

                jmp     infinite_loop

Boot_failure    endp

Subttl          Disk_reboot

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISK REBOOT                                |
; |                                                                       |
; |        Disk reboot. Sliboot track placed on a diskette that is        |
; |          not a Slidos master. Inform user to insert correct           |
; |                     diskette then perform reboot.                     |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_reboot     proc    near

                mov     si,offset reboot_message
                call    display_message

                mov     si,offset strike_any_key_message
                call    display_message

                mov     ah,0
                int     16h

                int     19h

Disk_reboot     endp

Subttl          Sli_dos_check

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                         SLI DOS CHECK                                |
; |                                                                      |
; |    Read in directory and verify that the first file listed is a      |
; |    file called wvdos.com.                                            |
; |                                                                      |
; |              Output:                                                 |
; |                      CY - 0 This is a valid Word Vision              |
; |                             shipping master.                         |
; |                      CY - 1 This is a invalid Word Vision            |
; |                             shipping master.                         |
; |                                                                      |
; ------------------------------------------------------------------------

Sli_dos_check  proc     near

               mov      ax,0201h
               mov      cx,0004h
               mov      dx,0
               mov      bx,0
               int      13h

               jnc      convert_to_lower_case

               call     boot_failure

        Convert_to_lower_case:

               mov      di,0
               mov      cx,0bh

               cld

        Convert_loop:

               or       byte ptr es:[di],20h
               inc      di

               loop     convert_loop

               mov      cx,0bh
               mov      di,0
               mov      si,offset sli_dos_name
               mov      dx,0bh

               repz     cmpsb

               jz       valid_disk

               stc
               jmp      sli_dos_check_return

        Valid_disk:

               clc

         Sli_dos_check_return:

               ret

Sli_dos_check  endp

Subttl         Display_message

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          DISPLAY MESSAGE                             |
; |                                                                      |
; |  Display message driver. Display string until a 0ffh is encountered  |
; |                                                                      |
; |              Input:                                                  |
; |                      CS:SI - contains address of message             |
; |                                                                      |
; ------------------------------------------------------------------------

Display_message proc    near

                mov     bx,0007h

                mov     ah,2
                mov     dx,cs:[si]
                int     10h 
              
                add     si,2

        Display_loop:

                mov     al,cs:[si]
                cmp     al,0ffh
                je      display_return

                mov     ah,0eh
                int     10h

                inc     si
                jmp     display_loop

        Display_return:

                mov     ah,2
                mov     dx,0ffffh
                int     10h 

                ret

Display_message endp

Code_seg        ends

                end     sli_boot
