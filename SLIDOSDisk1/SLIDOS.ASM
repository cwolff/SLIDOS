Name            SLIDOS

Title           Software_Labs_Inc_dos

Subttl          IBMBIO

Page 60,126

; *************************************************************************
; *                                                                       *
; *             (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                              IBMBIO                                  |
; |                                                                      |
; |       Set up label for Slidos to jump to after reading from disk     |
; |                                                                      |
; ------------------------------------------------------------------------

Ibm_bio_seg     segment at 60h

                org     00h

Ibm_bio         label   far

Ibm_bio_seg     ends

Subttl          Data

Page

Code_seg        segment public 'code'

                org     100h

                assume  cs:code_seg

;
; Externals
;

                extrn   sli_picture:near
                extrn   turn_monitor_on:near
                extrn   disk_on:near
                extrn   disk_off:near
                extrn   tab_on:near
                extrn   tab_off:near
                extrn   drive_on:near
                extrn   drive_off:near
                extrn   error_on:near
                extrn   error_off:near

;
; Publics
;

                public  display_message
                public  get_any_key
                public  clear_monitor
                public  number_of_drives
                public  color
                public  current_disk
                public  current_drive
                public  current_error
                public  picture_on_attribute
                public  picture_off_attribute
                public  monitor_attribute
                public  strike_any_key_message

                jmp     sli_dos

; Data Area to be used by boot

Ibm_bio_name                    db     'ibmbio  com'

Ibm_dos_name                    db     'ibmdos  com'

Sli_dos_name                    db     'slidos  com'

Total_no_of_sectors_to_read     dw     0014h

Disk_configuration              dw     0000

Disk_divisor                    db     01

Color                           db     0

Number_of_drives                db     0h

Picture_on_attribute            db     00h

Picture_off_attribute           db     00h

Monitor_attribute               db     00h

Error_attribute                 db     00h

Sector_size                     dw     200h

System_configuration            dw     00

Source_drive                    db     0

Destination_drive               db     0

Current_error                   db     0

Current_drive                   db     0

Current_disk                    db     0

Disk_retry                      db     0

; Preperation messages

Strike_any_key_message          db     25
                                db     ' To Continue Press a Key.'

Invalid_dos_message             db     60
                                db     ' Sorry, wrong disk. Please replace '
                                db     'with an IBM PC DOS disk. '

; Disk prompt messages

Insert_dos_message_1            db     25
	                        db     ' Please insert an IBM PC '
Insert_dos_message_2            db     25
                                db     '  DOS disk in drive '
Current_ibm_drive               db     ' :.  '

Invalid_wv_message              db     60
                                db     ' Sorry, wrong disk. Please replace '
                                db     'it with the Master disk. '

Insert_wv_message_1             db     25
                                db     '    Place the MASTER     '
Insert_wv_message_2             db     25
                                db     '    disk in Drive A:.    '

Invalid_ibm_message             db     71
                                db     ' Sorry, this DOS has been modified. '
	                        db     'Please insert a standard DOS disk. '

; Monitor configuration messages

Color_key_message               db     2,'F2'

Color_message                   db     13,'Color monitor'

Monochrome_key_message          db     2,'F4'

Monochrome_message              db     18,'Monochrome monitor'

; Drive configuration messages

One_drive_key_message           db     02,'F2'

One_drive_message               db     16,'One floppy drive'

Two_drive_key_message           db     02,'F4'

Two_Drive_message               db     17,'Two floppy drives'

One_drive_display               db     11,'           '

; Error messages

Drive_not_ready_message        db     66
                               db     ' Sorry, the disk drive is not working'
                               db     ' properly. Please adjust it. '

Write_protect_message          db     61
                               db     ' Please remove the "write protect" '
                               db     'tab from the MASTER disk. '

Sli_damaged_diskette_message    db     43
                                db     ' This Master Disk '
                                db     'appears to be defective. '

Damaged_diskette_message        db     54
                                db     ' This disk seems to be defective. '
                                db     'Please try another. '

Not_formatted_message           db     67
                                db     ' This disk is not formatted. '
                                db     'Please replace with a formatted ' 
                                db     'disk. '

Copyright_message               db     '(C)opyright 1983 Software '
                                db     'Laboratories Inc.'

Author_message                  db     'Author Cameron L. Wolff'

Subttl          Sli_dos

Page

; =========================================================================
; *                                                                       *
; *                               SLIDOS                                  *
; *                                                                       *
; *   Boot is read into memory by the PROM interrupt 19h. It check to     *
; *   to see if SLIDOS is present on the disk. If so read in IBMBIO.COM   *
; *   and IBMDOS.COM and transfer control to it (60:0)                    *
; *                                                                       *
; =========================================================================

Sli_dos         proc    near

                cli

; Set up segment registers and stack pointer

                mov     ax,cs
                mov     ds,ax
                mov     ax,60h
                mov     es,ax
                xor     ax,ax
                mov     ss,ax
                mov     sp,00h

                sti
 
                mov     ax,0600h
                mov     bh,00h
                mov     cx,0
                mov     dx,184fh
                int     10h

                mov     color,0

; Determine system configuration

        Equipment_determination:

                mov     number_of_drives,1

                int     11h

                mov     system_configuration,ax

                and     al,0c0h
                jz      display_picture

                mov     number_of_drives,2

; Picture 

        Display_picture:

                mov     picture_on_attribute,87h
                mov     picture_off_attribute,07h
                mov     monitor_attribute,07h
                mov     error_attribute,70h

                call    sli_picture

                call   turn_monitor_on

; Reset the disk system

                xor     ax,ax
                int     13h

; Determine if they have a color monitor

                call    display_mode

; Determine the number of drives

                call     drive_mode

; Set up for DOS load

                mov      al,destination_drive
                mov      current_drive,al
                mov      current_disk,1

        Insert_dos_prompt:

                call     ibm_dos_prompt

        Check_for_system:

                call     check_for_ibm_system

                jc       insert_dos_prompt      

        Check_for_patch:

                call    check_for_patched_ibm

                jc      insert_dos_prompt

        Check_disk_configuration:

                call    get_disk_configuration

                call    load_ibm_files

                jc      insert_dos_prompt 

; Ibm system file has been read in
; Instruct the user to to insert their working diskette

        Insert_sli_dos_prompt:

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,0

                mov     al,destination_drive
                cmp     source_drive,al
                jne     sli_dos_check

        Insert_sli_prompt:

                call    sli_dos_prompt

        Sli_dos_check:

                call    check_for_sli_dos

                jc      insert_sli_prompt

; Transfer control to IBMBIO.COM and IBMDOS.COM
; COMMAND.COM is back in control it makes the file invisible again.

        Bio_transfer:

                call    unprotect_command

                jc      insert_sli_prompt

                push    ds

                xor     ax,ax
                mov     ds,ax

                mov     bx,504h
                mov     byte ptr [bx],0

                pop     ds

                jmp     ibm_bio

Sli_dos         endp

Subttl          Boot_failure

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                            BOOT FAILURE                              |
; |                                                                      |
; ------------------------------------------------------------------------

Boot_failure    proc    near

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,1

                mov     bl,error_attribute
                mov     cx,offset sli_damaged_diskette_message
                mov     dx,18ffh
                call    display_message

        Failure_dos_prompt:

                call    ibm_dos_prompt

                call    check_for_ibm_system

                jc      failure_dos_prompt

                mov     ax,0600h
                mov     bh,07h
                mov     cx,0
                mov     dx,184fh
                int     10h

                int     19h

Boot_failure    endp

Subttl          Check_disk

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          CHECK DISK                                  |
; |                                                                      |
; |    Read in directory and verify that the first file listed is a      |
; |    file specified by the address of cs:si                            |
; |                                                                      |
; |              Input:                                                  |
; |                     CS:[SI] address of file to match                 |
; |                     DI offset into DTA for compare                   |
; |                                                                      |
; |              Output:                                                 |
; |                      CY - 0 This is a diskette prompted for          |
; |                      CY - 1 This is not a diskette prompted for      |
; |                                                                      |
; ------------------------------------------------------------------------

Check_disk     proc     near

               push     es

               mov      ax,0a00h
               mov      es,ax

               mov      disk_retry,3

        Check_disk_loop:

               mov      ax,0201h
               mov      cx,0004h
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      convert_to_lower_case

               mov      current_error,ah

               mov      ax,0
               int      13h

               dec      disk_retry
               jnz      check_disk_loop

               call     disk_failure

               mov      disk_retry,3
               jmp      check_disk_loop

        Convert_to_lower_case:

               push     di

               mov      cx,0bh

               cld

        Convert_loop:

               or       byte ptr es:[di],20h
               inc      di

               loop     convert_loop

               pop      di

               mov      cx,0bh

               repz     cmpsb

               jz       valid_disk

               stc

               jmp      check_disk_return

        Valid_disk:

               clc

         Check_disk_return:

               pop      es

               ret

Check_disk     endp

Subttl        Check_for_patched_dos

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                       CHECK FOR PATCHED IBM                          |
; |                                                                      |
; |    Read in directory and verify that their are only 2 protected      |
; |    files. Any more than that shows a modified IBM DOS diskette.      |
; |                                                                      |
; |              Output:                                                 |
; |                      CY - 0 This is the diskette prompted for        |
; |                      CY - 1 This is not the diskette prompted for.   |
; |                                                                      |
; ------------------------------------------------------------------------

Check_for_patched_ibm   proc     near

               push     es

               mov      ax,0a00h
               mov      es,ax

               mov      disk_retry,3

        Check_for_patch_loop:

               mov      ax,0201h
               mov      cx,0004h
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      check_for_protected_files

               mov      current_error,ah

               mov      ax,0
               int      13h

               dec      disk_retry
               jnz      check_for_patch_loop

               call     disk_failure

               mov      disk_retry,3
               jmp      check_for_patch_loop

        Check_for_protected_files:

               mov      al,es:[bx+11]
               cmp      al,6
               jne      invalid_ibm

               mov      al,es:[bx+11+32]
               cmp      al,6
               jne      invalid_ibm

               mov      al,es:[bx+11+32+32]
               cmp      al,0
               je       valid_ibm

        Invalid_ibm:

               mov     bl,error_attribute
               mov     cx,offset invalid_ibm_message
               mov     dx,18ffh
	       call    display_message

               stc

               jmp      check_ibm_return

        Valid_ibm:

               clc

         Check_ibm_return:

               pop      es

               ret

Check_for_patched_ibm   endp

Subttl         Get_disk_configuration

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                         GET DISK CONFIGURATION                        |
; |                                                                       |
; |       Determine if disk is a single or double sided disk              |
; |                                                                       |
; -------------------------------------------------------------------------

Get_disk_configuration proc near

               push     es

               mov      ax,0a00h
               mov      es,ax

               mov      disk_retry,3

        Check_configuration_loop:

               mov      ax,0201h
               mov      cx,0002h
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      check_single_or_double

               mov      current_error,ah

               mov      ax,0
               int      13h

               dec      disk_retry
               jnz      check_configuration_loop

               call     disk_failure

               mov      disk_retry,3
               jmp      check_configuration_loop

        Check_single_or_double:

               mov      bx,0
               mov      al,es:[bx]

               cmp      al,0feh
               je       single_drive

               mov      disk_configuration,0103h

               jmp      disk_configuration_return

        Single_drive:

               mov      disk_configuration,0008h

        Disk_configuration_return:             

               pop      es

               ret

Get_disk_configuration endp

Subttl         Display_mode

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          DISPLAY MODE                                 |
; |                                                                       |
; |      Determine if there is a color graphics card. If yes then ask     |
; |      if they have a color monitor. If yes again display in green.     |
; |      If no color card do not do any thing                             |
; |                                                                       |
; -------------------------------------------------------------------------

Display_mode    proc    near

                push    es

                mov     ax,0
                mov     es,ax

                mov     bx,101h
                mov     byte ptr es:[bx],0

                mov     ax,system_configuration

                and     al,30h

                cmp     al,30h

                jz      display_mode_return ; no color card

; Color graphics card present ask if they have a color monitor

                call    clear_monitor

                mov     bl,monitor_attribute
                mov     cl,4
                rol     bl,cl
                mov     cx,offset color_key_message
                mov     dx,031ah
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset color_message
                mov     dx,031dh
                call    display_message

                mov     bl,monitor_attribute
                mov     cl,4
                rol     bl,cl
                mov     cx,offset monochrome_key_message
                mov     dx,051ah
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset monochrome_message
                mov     dx,051dh
                call    display_message

                call    function_key

                call    clear_monitor

                jc      display_mode_return

                mov     bx,101h
                mov     byte ptr es:[bx],1

                mov     color,1

                mov     picture_on_attribute,83h
                mov     picture_off_attribute,03h
                mov     monitor_attribute,02h
                mov     error_attribute,47h

                call    sli_picture

        Display_mode_return:

                pop     es

                ret

Display_mode    endp

Subttl          drive_mode

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DRIVE MODE                                 |
; |                                                                       |
; |         If the system shows two disk drive ask the user if they       |
; |         are both Floppies.                                            |
; |                                                                       |
; -------------------------------------------------------------------------

Drive_mode      proc    near

                push    es

                mov     ax,0
                mov     es,ax

                mov     bx,100h
                mov     byte ptr es:[bx],0

                cmp     number_of_drives,1
                jne     test_for_floppy

                jmp     drive_mode_return

        Test_for_floppy:

                call    clear_monitor

                cmp     color,1
                jne     display_1st_prompt

                mov     monitor_attribute,04h

        Display_1st_prompt:

                mov     bl,monitor_attribute
                mov     cl,4
                rol     bl,cl
                mov     cx,offset one_drive_key_message
                mov     dx,031ah
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset one_drive_message
                mov     dx,031dh
                call    display_message

                cmp     color,1
                jne     display_2nd_prompt
 
                mov     monitor_attribute,06h

        Display_2nd_prompt:

                mov     bl,monitor_attribute
                mov     cl,4
                rol     bl,cl
                mov     cx,offset two_drive_key_message
                mov     dx,051ah
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset two_drive_message
                mov     dx,051dh
                call    display_message

                mov     monitor_attribute,07h

                call    function_key

                call    clear_monitor

                mov     destination_drive,1

                mov     bx,100h
                mov     byte ptr es:[bx],1

                jc      drive_mode_return

                mov     destination_drive,0

                mov     bx,100h
                mov     byte ptr es:[bx],0

                mov     cx,offset one_drive_display
                mov     dx,0b2dh
                call    display_message

        Drive_mode_return:

                pop     es

                ret

Drive_mode      endp

Subttl          Function_key

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             FUNCTION KEY                              |
; |                                                                       |
; |         Get response from user. If F2 set carry If F1 clear carry     |
; |         Do not exit unless F2 or F4 is entered                        |
; |                                                                       |
; -------------------------------------------------------------------------

Function_key proc    near

                clc

        Get_function_key:

                call    get_any_key

                cmp     ah,3ch
                je      function_key_return

                cmp     ah,3eh
                jne     get_function_key

                stc

        Function_key_return:

                ret

Function_key endp

Subttl          Get_any_key

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           GET ANY KEY                                 |
; |                                                                       |
; |        Gets a key from the key board after flushing it first          |
; |                                                                       |
; -------------------------------------------------------------------------

Get_any_key     proc    near

        Flush_key_buffer:

                mov     ah,1
                int     16h

                jz      get_key

                mov     ah,0
                int     16h

                jmp     flush_key_buffer

        Get_key:

                mov     ah,00h
                int     16h

                ret

Get_any_key     endp

Subttl          Display_message

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          DISPLAY MESSAGE                             |
; |                                                                      |
; |  Display message driver. Display string until a 0ffh is encountered  |
; |                                                                      |
; |              Input:                                                  |
; |                      CS:SI - contains address of message             |
; |                         BL - attribute                               |
; |                                                                      |
; |                                                                      |
; ------------------------------------------------------------------------

Display_message proc    near

                push    ax
                push    bx
                push    cx
                push    dx
                push    bp
                push    si

; Set up display message and check limits

                mov     si,cx
                mov     al,[si]
                xor     ah,ah
                mov     bh,al
                dec     bh
                cmp     al,0
                jbe     display_message_return
                cmp     dl,04fh
                jbe     message_positioned
                inc     bh
                shr     bh,1
                mov     dl,27h

        Message_positioned:

                add     dl,bh
                cmp     dl,04fh
                jg      display_message_return
                cmp     dh,18h
                jg      display_message_return

        Display_loop:

                push    ax
                push    bx

                mov     ah,2
                mov     bh,0
                int     10h

                pop     bx
                pop     ax

                push    ax
                push    bx
                push    si

                mov     bp,ax
                mov     al,cs:[si+bp]
                mov     bh,0
                mov     cx,1
                mov     ah,9
                int     10h

                pop     si
                pop     bx
                pop     ax

                sub     dl,1
                sub     al,1
                jnz     display_loop

; Place cursor off the screen

                mov     ah,2
                mov     bh,0
                mov     dx,0ffffh
                int     10h

        Display_message_return:

                pop     si
                pop     bp
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Display_message endp

Subttl          Clear_monitor

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            CLEAR MONITOR                              |
; |                                                                       |
; -------------------------------------------------------------------------

Clear_monitor   proc    near

                pushf
                push    ax

                mov     ax,0600h
                mov     bh,07
                mov     cx,0219h
                mov     dx,0630h
                int     10h

                pop     ax
                popf

                ret

Clear_monitor   endp

Subttl          Clear_error

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            CLEAR ERROR                                |
; |                                                                       |
; -------------------------------------------------------------------------

Clear_error     proc    near

                pushf
                push    ax

                mov     ax,0600h
                mov     bh,07
                mov     cx,1800h
                mov     dx,184fh
                int     10h

                pop     ax
                popf

                ret

Clear_error     endp

Subttl          Unprotect_command

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           UNPROTECT COMMAND                           |
; |                                                                       |
; -------------------------------------------------------------------------

Unprotect_command proc  near

               push     es

               mov      ax,0b00h
               mov      es,ax

               mov      disk_retry,3

        Read_directory_loop:

               mov      ax,0201h
               mov      cx,0004h
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      set_command_to_visible

               mov      current_error,ah

               mov      ah,0
               int      13h

               dec      disk_retry
               jnz      read_directory_loop

               call     disk_failure

               call     check_for_sli_dos
               jnc      read_directory_loop_continue

               stc

               jmp      unprotect_return

        Read_directory_loop_continue:

               mov      disk_retry,3
               jmp      read_directory_loop

        Set_command_to_visible:

               mov      byte ptr es:[bx+11+32],00
 
               mov      disk_retry,1

        Write_directory_loop:

               mov      ax,0301h
               mov      cx,0004h
               mov      dh,0
               mov      dl,current_drive
               mov      bx,0
               int      13h

               jnc      unprotect_return

               mov      current_error,ah

               mov      ah,0
               int      13h

               dec      disk_retry
               jnz      write_directory_loop

               call     disk_failure

               call     check_for_sli_dos
               jnc      write_directory_loop_continue

               stc

               jmp      unprotect_return

        Write_directory_loop_continue:

               mov      disk_retry,3

               jmp      read_directory_loop

        Unprotect_return:

               pop      es

               ret

Unprotect_command endp

Subttl          Load_ibm_files

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            LOAD IBM FILES                             |
; |                                                                       |
; -------------------------------------------------------------------------

Load_ibm_files  proc    near

                push    es

                mov     ax,ibm_bio_seg
                mov     es,ax

        Load_ibm_files_error_loop:

                cmp     disk_configuration,08h
                je      single_sided_disk

                mov     disk_divisor,2

        Single_sided_disk:

                mov     bx,00h
                mov     cx,disk_configuration

                push    cx

                mov     al,09
                sub     al,cl
                mov     ah,0
                mov     si,ax

                mov     disk_retry,3

        Read_ibm_loop:

                push    si
                push    bx

                xor     dx,dx
                xor     ax,ax
                mov     al,ch
                div     disk_divisor
                mov     ch,al
                mov     dh,ah
                mov     dl,current_drive
                mov     ax,si
                mov     ah,02

                int     13h

                jnc     continue_ibm_read

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     read_ibm_loop

                call    disk_failure

; Make sure there is still a IBM DOS disk present

                pop     bx
                pop     si
                pop     cx

                call    check_for_ibm_system

                jc      not_an_ibm_disk

        Ibm_patch_test:

                call    check_for_patched_ibm 

                jc      not_an_ibm_disk

                jmp     load_ibm_files_error_loop

        Not_an_ibm_disk:

                stc

                jmp     load_ibm_files_return

        Continue_ibm_read:

                pop     bx
                pop     si
                pop     cx

                sub     total_no_of_sectors_to_read,si
                jz      load_ibm_files_return

                mov     ax,si
                mul     sector_size
                add     bx,ax
                inc     ch
                mov     cl,01

                push    cx

                mov     si,8
                cmp     si,total_no_of_sectors_to_read
                jl      end_of_ibm_read_loop

                mov     si,total_no_of_sectors_to_read

        End_of_ibm_read_loop:

                mov     disk_retry,3

                jmp     read_ibm_loop

        Load_ibm_files_return:

                pop     es

                ret

Load_ibm_files  endp

Subttl          Disk_failure

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISK FAILURE                               |
; |                                                                       |
; |       Input:                                                          |
; |                                                                       |
; |             current_error - disk error code                           |
; |             current_drive - 0,drive a: 1,drive b:                     |
; |             current disk  - 0,master 1,ibm dos 2,working              |
; |                    If Master and fatal error, reboot                  |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_failure    proc    near

                cmp     current_error,80h
                jne     check_format_error

                mov     cx,offset drive_not_ready_message
                jmp     display_disk_error

        Check_format_error:

                cmp     current_error,04h
                jne     check_write_protect_error

                mov     cx,offset not_formatted_message
                jmp     display_disk_error

        Check_write_protect_error:

                cmp     current_error,03h
                jne     fatal_error

                mov     cx,offset write_protect_message
                jmp     display_disk_error

        Fatal_error:

                cmp     current_disk,0
                jne     not_word_vision_diskette

                call    boot_failure

        Not_word_vision_diskette:

                mov     cx,offset damaged_diskette_message

        Display_disk_error:

                push    cx

                call    error_on

                pop     cx

                mov     bl,error_attribute
                mov     dx,18ffh
                call    display_message

                call    get_any_key

                call    error_off

                call    clear_error

                ret

Disk_failure    endp

Subttl          Check_for_ibm_system

Page

; ========================================================================
; |                                                                      |
; |                      CHECK FOR IBM SYSTEM                            |
; |                                                                      |
; ========================================================================

Check_for_ibm_system proc near

        Check_for_ibm_bio:

                mov     si,offset ibm_bio_name
                mov     di,00h
                call    check_disk

                jnc     check_for_ibm_dos

                jmp     invalid_ibm_disk

        Check_for_ibm_dos:

                mov     si,offset ibm_dos_name
                mov     di,20h
                call    check_disk

                jnc     check_for_ibm_system_return

        Invalid_ibm_disk:

                mov     bl,error_attribute
                mov     cx,offset invalid_dos_message
                mov     dx,18ffh
                call    display_message

                stc

        Check_for_ibm_system_return:

                ret

Check_for_ibm_system endp

Subttl          Sli_dos

Page

; ========================================================================
; |                                                                      |
; |                            CHECK FOR SLI DOS                         |
; |                                                                      |
; ========================================================================

Check_for_sli_dos proc near

                mov     si,offset sli_dos_name
                mov     di,0
                call    check_disk

                jnc     check_for_sli_return

                mov     bl,error_attribute
                mov     cx,offset invalid_wv_message
                mov     dx,18ffh
                call    display_message

                stc

        Check_for_sli_return:

                ret

Check_for_sli_dos endp

Subttl          Ibm_dos_prompt

Page

; =========================================================================
; |                                                                       |
; |                         IBM DOS PROMPT                                |
; |                                                                       |
; =========================================================================

Ibm_dos_prompt  proc    near

                mov     al,current_drive
                add     al,41h
                mov     current_ibm_drive,al

                mov     bl,monitor_attribute
                mov     cx,offset insert_dos_message_1
                mov     dx,0218h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset insert_dos_message_2
                mov     dx,0418h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset strike_any_key_message
                mov     dx,0618h
                call    display_message

                mov     al,current_drive
                call    drive_on

                mov     al,current_disk
                call    disk_on

                call    get_any_key

                call    clear_monitor

                mov     al,current_drive
                call    drive_off

                mov     al,current_disk
                call    disk_off

                call    clear_error

                ret

Ibm_dos_prompt  endp

Subttl          Sli_dos_prompt

Page

; =========================================================================
; |                                                                       |
; |                              SLI DOS PROMPT                           |
; |                                                                       |
; =========================================================================

Sli_dos_prompt  proc    near

                mov     bl,monitor_attribute
                mov     cx,offset insert_wv_message_1
                mov     dx,0218h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset insert_wv_message_2
                mov     dx,0418h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset strike_any_key_message
                mov     dx,0618h
                call    display_message

                mov     al,current_drive
                call    drive_on

                mov     al,current_disk
                call    disk_on

                call    get_any_key

                call    clear_monitor

                mov     al,current_drive
                call    drive_off

                mov     al,current_disk
                call    disk_off

                call    clear_error

                ret

Sli_dos_prompt  endp

Code_seg        ends

                end
