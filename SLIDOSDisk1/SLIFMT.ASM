Name            SLIFMT

Title           Software_labs_inc_command

Subttl          Format_working_copy

Page 60,132

; *************************************************************************
; *                                                                       *
; *             (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Code_seg        segment public 'code'

                assume  cs:code_seg

;
; Include external data file
;

                include c:slidata.inc

;
; External procedures
;

                extrn   display_message:near
                extrn   disk_failure:near
                extrn   clear_monitor:near
                extrn   clear_error:near
                extrn   function_key:near
                extrn   get_any_key:near
                extrn   verify_master:near
                extrn   verify_work:near
                extrn   read_ibm_files:near
                extrn   write_ibm_files:near
                extrn   check_disk:near
                extrn   drive_on:near
                extrn   drive_off:near
                extrn   disk_on:near
                extrn   disk_off:near
                extrn   tab_on:near
                extrn   tab_off:near
                extrn   work_prompt:near
               
;
; Public procedure
;

                public  format_work_copy

Page

; =========================================================================
; |                                                                       |
; |                            FORMAT WORK COPY                           |
; |                                                                       |
; |      Format working copy only if it is not formatted. If there        |
; |      are files check to see if there is enough room on the disk       |
; |      for the Word Vision working copy files. If there isnt            |
; |      enough room inform the user. If there is enough room inform      |
; |      the user that there are files on the disk and ask them if        |
; |      1) they want them destroyed or 2) they want the word vision      |
; |      added to the disk.                                               |
; |                                                                       |
; =========================================================================

Format_work_copy proc   near

                mov     al,destination_drive
                mov     current_drive,al
                mov     current_disk,2

        Format_work_copy_prompt:

                call    work_prompt

                call    check_if_blank_disk

                jc      format_work_copy_prompt

                cmp     al,0
                jne     inform_user_disk_not_empty

                jmp     format_disk_operation

; Disk not blank, inform user if this is what they want

        Inform_user_disk_not_empty:

                call   verify_work

                jc     format_work_copy_prompt

                call   clear_monitor

                cmp    color,1
                jne    erase_prompt

                mov    monitor_attribute,04h

        Erase_prompt:

                mov    bl,monitor_attribute
                mov    cx,offset erase_key_files_message
                mov    dx,031ah
                call   display_message

                mov    bl,monitor_attribute
                mov    cx,offset erase_files_message
                mov    dx,031dh
                call   display_message
                 
                cmp    color,1
                jne    add_prompt

                mov    monitor_attribute,06h

        Add_prompt:

                mov    bl,monitor_attribute
                mov    cx,offset add_key_files_message
                mov    dx,051ah
                call   display_message

                mov    bl,monitor_attribute
                mov    cx,offset add_files_message
                mov    dx,051dh
                call   display_message

                mov    monitor_attribute,07h

                cmp    color,1
                jne    get_function_response

                mov    monitor_attribute,02h

        Get_function_response:

                call   function_key

                call   clear_monitor

                jnc    format_disk_operation

                call   verify_size

                jnc    dos_check_operation

                mov    bl,error_attribute
                mov    cx,offset not_enough_space_message
                mov    dx,18ffh
                call   display_message

                jmp    format_work_copy

; See if it contains ibm files necessary to boot disk

        Dos_check_operation:

                mov     al,destination_drive
                mov     current_drive,al
                mov     current_disk,2

                call    ibm_dos_check

                jnc     format_work_copy_return

                jmp     format_work_copy

        Format_disk_operation:

                call   format_driver

                jnc    read_dos_files

                jmp    format_work_copy

        Read_dos_files:

                call   read_ibm_files

                call   write_ibm_files

                jnc    format_work_copy_return

                jmp    format_work_copy

        Format_work_copy_return:

                call   clear_monitor

                ret

Format_work_copy endp

Subttl          Check_if_blank_disk

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          CHECK IF BLANK DISK                          |
; |                                                                       |
; |                       Determine if disk is blank                      |
; |       Also verifies that it is not a word vision master diskette      |
; |                                                                       |
; |         Output:                                                       |
; |                 CY - 1  fatal disk error                              |
; |                      CY - 0 successful test                           |
; |                           AL - 0 blank disk                           |
; |                           AL - 1 not blank disk                       |
; |                                                                       |
; |                                                                       |
; -------------------------------------------------------------------------

Check_if_blank_disk proc near

                mov     disk_retry,3

        Blank_test_loop:

                mov     ax,0408h
                mov     cx,0001h
                mov     dh,0
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     disk_not_blank

                mov     current_error,ah

                xor     ax,ax
                int     13h

                test    current_error,00000110b
                jz      blank_test_error

                jmp     blank_disk

        Blank_test_error:

                dec     disk_retry
                jnz     blank_test_loop

                call    disk_failure

                mov     disk_retry,3

                jmp     blank_test_loop

        Blank_test_loop_continue:

                mov     disk_retry,3

                jmp     blank_test_loop

        Disk_not_blank:

                mov     bx,offset file_control_block
                mov     dx,bx
                mov     al,current_drive
                inc     al
                mov     [bx],al
                mov     di,bx
                inc     di
                mov     si,offset any_file_name
                mov     cx,11

                rep     movsb

                mov     ah,11h
                int     21h

                cmp     al,0
                je      not_blank

        Blank_disk:

                clc

                mov     al,0

                jmp     check_if_blank_return

        Not_blank:
                
                clc

                mov     al,1

        Check_if_blank_return:

                ret

Check_if_blank_disk endp

Subttl

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          IMB DOS CHECK                                |
; |                                                                       |
; |        Check to see if disk contains ibmbio.com, ibmdos.com           |
; |        and command.com files                                          |
; |                                                                       |
; |        Output:                                                        |
; |                CY - 0 contains ibm operating system                   |
; |                CY - 1 dosent contain ibm files.                       |
; |                                                                       |
; -------------------------------------------------------------------------

Ibm_dos_check   proc    near

                mov     si,offset ibm_bio_name
                mov     di,0

                call    check_disk

                jc      ibm_dos_check_error

                mov     si,offset ibm_dos_name
                mov     di,20h

                call    check_disk

                jc      ibm_dos_check_error

                mov     bx,offset file_control_block
                mov     dx,bx
                mov     al,current_drive
                inc     al
                mov     [bx],al
                mov     di,bx
                inc     di
                mov     si,offset command_name
                mov     cx,11

                rep     movsb

                mov     ah,11h
                int     21h

                cmp     al,0
                je      ibm_dos_check_return

        Ibm_dos_check_error:

                mov     bl,error_attribute
                mov     cx,offset no_room_for_system_message
                mov     dx,18ffh
                call    display_message

                stc

        Ibm_dos_check_return:

                ret

Ibm_dos_check   endp

Subttl          Format_driver

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             FORMAT DRIVER                             |
; |                                                                       |
; |         Determine if single or double sided format of diskette        |
; |                                                                       |
; |          CY - 0 succeful operation CY - 1 fatal error                 |
; |                                                                       |
; -------------------------------------------------------------------------

Format_driver   proc    near

        Display_format_operation:

                mov     disk_retry,3

                mov     bl,monitor_attribute
                mov     cx,offset format_message_1
                mov     dx,0318h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset format_message_2
                mov     dx,0518h
                call    display_message

        Format_driver_loop:

                mov     ax,0000h
                call    set_format_parameters

                int     13h

                jnc     check_side_two

                mov     current_error,ah

                mov     ax,0
                int     13h

                dec     disk_retry
                jnz     format_driver_loop

                call    disk_failure

                stc

                jmp     format_driver_return

; Format second side and verify to check if two heads on drive

        Check_side_two:

                mov     ax,0001h
                call    set_format_parameters

                int     13h

                mov     ax,0408h
                mov     cx,0001h
                mov     dh,01              ; second side
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     format_two_sides

                mov     number_of_sides,0
                jmp     format_disk

        Format_two_sides:

                mov     number_of_sides,1

        Format_disk:

                mov     ax,0100h
                mov     current_track_side,ax
                mov     disk_retry,3

        Format_disk_loop:

                call    set_format_parameters

                int     13h

                jnc     next_track_or_side

                mov     current_error,ah

                mov     ax,0
                int     13h

                dec     disk_retry
                jz      format_disk_error
                
                mov     ax,current_track_side
                jmp     format_disk_loop

        Format_disk_error:

                call    disk_failure

                stc

                jmp     format_driver_return

        Next_track_or_side:

                cmp     number_of_sides,0
                je      next_track
 
                mov     ax,current_track_side
                cmp     al,0
                jne     next_track

                mov     al,1
                mov     current_track_side,ax
                jmp     format_disk_loop

        Next_track:

                mov     ax,current_track_side
                mov     al,0
                inc     ah
                mov     current_track_side,ax

                cmp     ah,40
                je      format_done

                jmp     format_disk_loop

        Format_done:

                call    set_fat_and_directory

        Format_driver_return:

                call    clear_monitor

                ret

Format_driver   endp

Subttl          Set_format_parameters

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                       SET FORMAT PARAMETERS                           |
; |                                                                       |
; |          Sets format parameters and set the registers for the         |
; |                       next format operations                          |
; |                                                                       |
; |         CY - 0 successful operation    CY - 1 fatal error             |
; |                                                                       |
; -------------------------------------------------------------------------

Set_format_parameters proc near

                mov     bx,offset format_block

                mov     dl,1
                mov     dh,2

                mov     cx,8

        Set_block_loop:

                mov     [bx],ah
                mov     [bx+1],al
                mov     [bx+2],dl
                mov     [bx+3],dh

                add     bx,4
                inc     dl

                loop    set_block_loop

; Set registers for next format operation

                mov     bx,offset format_block

                mov     ax,0508h
                mov     ch,[bx]
                mov     cl,1
                mov     dh,[bx+1]
                mov     dl,current_drive

                ret

Set_format_parameters endp

Subttl          Set_fat_and_directory

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                        SET FAT AND DIRECTORY                          |
; |                                                                       |
; |          Set the file allocation table and the directory              |
; |                                                                       |
; |       Output:                                                         |
; |              CY - 1 fatal error                                       |
; |              CY - 0 successful operation                              |
; |                                                                       |
; -------------------------------------------------------------------------

Set_fat_and_directory proc near

                push    es

                mov     ax,general_dta_seg
                mov     es,ax

                mov     si,offset disk_io_parameters

                mov     byte ptr [si],2
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],2
                mov     byte ptr [si+3],0

                call    fat_dir_disk_io

                jnc     initialize_fat

                jmp     set_fat_dir_return

        Initialize_fat:

                cmp     number_of_sides,0
                je      single_sided

                mov     dx,1dch
                jmp     format_fat

        Single_sided:

                mov     dx,1d9h

        Format_fat:

                mov     di,0
                mov     cx,dx
                mov     al,00h

                rep     stosb

                mov     ax,0ffffh

                mov     bx,1
                mov     es:[bx],ax

                mov     ah,0feh
                or      ah,number_of_sides

                mov     bx,0
                mov     es:[bx],ah

; Write fat table to track 0 sector 2 and 3

                mov     si,offset disk_io_parameters

                mov     byte ptr [si],3
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],2
                mov     byte ptr [si+3],0
                mov     cx,2

        Write_fat_loop:

                call    fat_dir_disk_io

                jc      write_fat_error

                inc     byte ptr [si+2]

                loop    write_fat_loop

                jmp     read_directory

        Write_fat_error:

                jmp     set_fat_dir_return

; Read in sector for directory

        Read_directory:

                mov     si,offset disk_io_parameters

                mov     byte ptr [si],2
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],4
                mov     byte ptr [si+3],0

                call    fat_dir_disk_io

                jnc     Initialize_directory

                jmp     set_fat_dir_return

        Initialize_directory:

                mov     bx,0
                mov     cx,16
                mov     al,0e5h

        Initialize_directory_loop:

                mov     es:[bx],al
                add     bx,20h

                loop    initialize_directory_loop

; Set dir to track 0 sectors 4 through 7 then test for double sided disk

                mov     si,offset disk_io_parameters

                mov     byte ptr [si],3
                mov     byte ptr [si+1],0
                mov     byte ptr [si+2],4
                mov     byte ptr [si+3],0

                mov     cx,4

        Write_directory_loop:

                call    fat_dir_disk_io

                jc      write_directory_error

                inc     byte ptr [si+2]

                loop    write_directory_loop

                jmp     check_for_second_side

        Write_directory_error:

                jmp     set_fat_dir_return

        Check_for_second_side:

                cmp     number_of_sides,0
                je      set_fat_dir_return

; Double sided disk expand directory

                call    fat_dir_disk_io    ; sector 8 side 0

                jc      set_fat_dir_return

                mov     byte ptr [si+2],1
                mov     byte ptr [si+3],1
                mov     cx,2

        Dir_second_side_loop:

                call    fat_dir_disk_io

                jc      set_fat_dir_return

                inc     byte ptr [si+2]

                loop    dir_second_side_loop

                clc

        Set_fat_dir_return:

                pop     es

                ret

Set_fat_and_directory endp

Subttl          Fat_dir_disk_io

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            FAT DIR DISK IO                            |
; |                                                                       |
; |        Input:                                                         |
; |                SI - address of operation string                       |
; |                     [si] - operation                                  |
; |                     [si+1] - track number                             |
; |                     [si+2] - sector number                            |
; |                     [si+3] - head number                              |
; |                                                                       |
; |       Output:                                                         |
; |                CY - 0 Succeful operation                              |
; |                CY - 1 Fatal error                                     |
; |                                                                       |
; -------------------------------------------------------------------------

Fat_dir_disk_io proc    near

                push    cx

                mov     disk_retry,3

        Fat_dir_disk_io_loop:

                mov     ah,[si]
                mov     al,1
                mov     ch,[si+1]
                mov     cl,[si+2]
                mov     dh,[si+3]
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     fat_dir_disk_io_return

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     fat_dir_disk_io_loop

                call    disk_failure

                stc

        Fat_dir_disk_io_return:

                pop     cx

                ret

Fat_dir_disk_io endp

Subttl          Verify_size

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             VERIFY SIZE                               |
; |                                                                       |
; |         Determines if there is enough space on diskette for word      |
; |         vision                                                        |
; |                                                                       |
; -------------------------------------------------------------------------

Verify_size     proc    near

                mov     ah,0eh
                mov     dl,current_drive
                int     21h

; Get File Allocation Table

                push    ds

                mov     ah,1bh
                int     21h

                push    ax                 ; save # record per allocation

                mov     cx,dx
                mov     ax,0

; Determine number of free allocation units

        Fat_free_loop:

                add     bx,3
                mov     dx,[bx]
                and     dx,0fffh
                jnz     sector_used

                inc     ax

        Sector_used:

                dec     cx
                jz      size_check_done

                mov     dx,[bx+1]
                and     dx,0fff0h
                jnz     sector_used_also

                inc     ax

        Sector_used_also:

                loop     fat_free_loop

        Size_check_done:

                pop      cx

                pop      ds

; AX = number of allocation unit free CL = no of record per allocation unit

                cmp      cl,1
                je       one_record_per_unit

                cmp      ax,298
                jb       not_enough_space

                jmp      check_directory_for_space

        One_record_per_unit:

                cmp      ax,149
                jb       not_enough_space

; Check to see if there is enough space in directory for 10 files

        Check_directory_for_space:

                push    cx                 ; save record/allocation units

                mov     bx,offset file_control_block
                mov     dx,bx
                mov     al,current_drive
                inc     al
                mov     [bx],al
                mov     di,bx
                inc     di
                mov     si,offset any_file_name
                mov     cx,11

                rep     movsb

                mov     ah,11h
                int     21h

                mov     cl,1

                cmp     al,0
                jne     file_count_done

        File_count_loop:

                push    cx

                mov     bx,offset file_control_block
                mov     dx,bx
                mov     al,current_drive
                mov     [bx],al
                mov     di,bx
                inc     di
                mov     si,offset any_file_name
                mov     cx,11

                mov     ah,12h
                int     21h

                pop     cx

                cmp     al,0
                jne     file_count_done

                inc     cl
                jmp     file_count_loop

        File_count_done:

                pop     dx

                cmp     dl,1
                jne     double_sided_directory

                cmp     cl,30
                ja      not_enough_space

                jmp     enough_space

        Double_sided_directory:

                cmp     cl,80
                ja      not_enough_space

        Enough_space:

                 clc

                 jmp     verify_size_return

        Not_enough_space:

                stc

        Verify_size_return:

                ret

Verify_size     endp

Code_seg        ends

                end
