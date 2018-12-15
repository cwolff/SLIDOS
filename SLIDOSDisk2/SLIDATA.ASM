Name            SLIDATA

Title           Software_labs_inc_command

Subttl          Sli_data

Page 60,132

; *************************************************************************
; *                                                                       *
; *             (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

;
; Externals
;

                extrn   display_message:near
                extrn   clear_monitor:near
                extrn   clear_error:near
                extrn   get_any_key:near

Page

;
; Public messages
;

                public  sli_dos_name,ibm_bio_name,ibm_dos_name,command_name
                public  strike_any_key_message
                public  damaged_diskette_message
                public  not_formatted_message,write_protect_message
                public  drive_not_ready_message
                public  not_enough_space_message,working_drive
                public  working_copy_message_1,working_copy_message_2
                public  insert_master_message_1,insert_master_message_2
                public  not_write_protected_message
                public  not_ibm_message,format_message_1,format_message_2
                public  not_working_message,not_master_message
                public  please_write_protect_message_1,insert_ibm_message_1
                public  please_write_protect_message_2,insert_ibm_message_2
                public  no_room_for_system_message
                public  reading_ibm_message_1,writing_ibm_message_1
                public  reading_ibm_message_2,writing_ibm_message_2
                public  reading_master_message_1
                public  reading_master_message_2,writing_working_message_1
                public  writing_working_message_2
                public  fatal_master_message,fatal_work_message
                public  erase_key_files_message,erase_files_message
                public  add_key_files_message,add_files_message
                public  fatal_ibm_message

Page

;
; Public subroutine
;

                public  monitor_off,drive_on,drive_off,disk_on
                public  disk_off,tab_on,tab_off,error_on,error_off
                public  progress_on,progress_off

;
; Public variables
;

                public  source_drive,destination_drive
                public  number_of_drives,current_drive
                public  attribute,disk_retry,format_block,current_track_side
                public  file_control_block,any_file_name,number_of_sides
                public  general_dta_seg,search_fcb,create_fcb
                public  file_1_fcb,file_2_fcb,file_3_fcb
                public  file_1_dta,file_2_dta,file_3_dta,end_of_3_dta
                public  disk_io_parameters,current_memory_position
                public  picture_on_attribute,picture_off_attribute
                public  monitor_attribute,error_attribute
                public  current_disk,current_error,color,current_drive
                public  end_of_data

Subttl          Messages

Page

Code_seg        segment public 'code'

                assume  cs:code_seg

; =========================================================================
; *                                                                       *
; *                              MESSAGES                                 *
; *                                                                       *
; *                                                                       *
; =========================================================================

Sli_dos_name                    db     'slidos  com'

Ibm_bio_name                    db     'ibmbio  com'

Ibm_dos_name                    db     'ibmdos  com'

Command_name                    db     'command com'

Any_file_name                   db     11 dup ('?')

; Dos messages

Strike_any_key_message          db     25
                                db     ' To continue press a key.'

Insert_master_message_1         db     25
                                db     '   Insert the MASTER     '
Insert_master_message_2         db     25
                                db     '    Disk in Drive A:.    '

Not_master_message              db     60
                                db     ' Sorry, wrong disk. Please replace '
                                db     'it with the MASTER disk. '

Not_working_message            db     59
                               db     ' Sorry wrong disk. Please replace '
                               db     'it with the WORKING disk. '

Not_ibm_message                db     63
                               db     ' Sorry wrong disk. Please replace it '
                               db     'with the IBM PC DOS disk. '

No_room_for_system_message      db     71
                                db     ' The sytsem will not fit on the '
                                db     'this WORKING Disk. '
                                db     'Please try another. '

Fatal_master_message            db     72
                                db     ' This MASTER disk is '
                                db     'Defective, Please place the '
                                db     'IBM PC DOS in Drive A: '

Damaged_diskette_message        db     45
                                db     ' This disk is defective. Please '
                                db     'try another. '

Not_formatted_message           db     49
                                db     ' This disk is not formatted, Please '
                                db     'try another. '

Write_protect_message           db     70
                                db     ' This disk is write protected, '
                                db     'Please remove the "write protect" '
                                db     'tab. '

Drive_not_ready_message        db     66
                               db     ' Sorry, the disk drive is not working'
                               db     ' properly. Please adjust it. '

Working_copy_message_1          db     25
                                db     '   Insert the WORKING    '
Working_copy_message_2          db     25
                                db     '    disk in drive '
Working_drive                   db     'X:.    '

Insert_ibm_message_1            db     25
                                db     '  Insert the IBM PC DOS  '
Insert_ibm_message_2            db     25
                                db     '    disk in drive A:.    '

Reading_ibm_message_1           db     25
                                db     'Reading IBM PC DOS system'
Reading_ibm_message_2           db     25
                                db     'from the IBM PC Dos Disk.'

Writing_ibm_message_1           db     25
                                db     'Writing IBM PC DOS system'
Writing_ibm_message_2           db     25
                                db     '   to the WORKING disk.  '

Reading_master_message_1        db     25
                                db     '  Reading MASTER files   '
Reading_master_message_2        db     25
                                db     '  from the MASTER disk.  '

Writing_working_message_1       db     25
                                db     '  Writing MASTER files   '
Writing_working_message_2       db     25
                                db     '  to the WORKING disk.   '

Not_working_diskette            db     52
                                db     ' Sorry, wrong disk. Please insert '
                                db     'the WORKING disk. '  

Erase_key_files_message         db     1,05

Erase_files_message             db     19
                                db     'Erase WORKING disk.'

Add_key_files_message           db     1,04

Add_files_message               db     20
                                db     'Add to Working disk.'

Not_enough_space_message        db     63
                                db     ' Sorry, there is not enough space '
                                db     'on Disk. Please try another. '

Not_write_protected_message     db     73
                                db     ' Sorry, MASTER is not '
                                db     'write protected, Please do so for '
                                db     'your protection. '

Please_write_protect_message_1  db     25
                                db     'Place a write protect tab'
Please_write_protect_message_2  db     25
                                db     '   on your MASTER Disk.  '

Format_message_1                db     25
                                db     '        Formating        '
Format_message_2                db     25
                                db     '      WORKING Disk.      '

Fatal_work_message              db     58
                                db     ' Sorry, unable to create WORKING '
                                db     ' disk. Please try again. '

Fatal_ibm_message               db     63
                                db     ' This IBM DOS disk appears to be '
                                db     'defective, please try another '

Subttl          Variables

Page

; =========================================================================
; |                                                                       |
; |                             VARIABLES                                 |
; |                                                                       |
; =========================================================================

Color                           db     00h

Picture_on_attribute            db     00h

Picture_off_attribute           db     00h

Monitor_attribute               db     00h

Error_attribute                 db     00h

Source_drive                    db     00h

Destination_drive               db     00h

Current_drive                   db     00h

Current_disk                    db     00h

Current_error                   db     00h

Number_of_drives                db     00h

Attribute                       db     00h

Disk_retry                      db     00h

Number_of_sides                 db     00h

Current_track_side              dw     0000h

General_dta_seg                 dw     0000h

Disk_io_parameters              db     4 dup (00)

Current_memory_position         dw     0000h

Search_fcb                      db     44 dup (00)

Create_fcb                      db     44 dup (00)

File_1_dta                      dw     0000

File_1_fcb                      db     44 dup (00)

File_2_dta                      dw     0000

File_2_fcb                      db     44 dup (00)

File_3_dta                      dw     0000

File_3_fcb                      db     44 dup (00)

End_of_3_dta                    dw     0000

File_control_block              db     44 dup (00)

Format_block                    db     00,00,01,02
                                db     00,00,02,02
                                db     00,00,03,02
                                db     00,00,04,02
                                db     00,00,05,02
                                db     00,00,06,02
                                db     00,00,07,02
                                db     00,00,08,02


Subttl          Pictures

Page

; =========================================================================
; |                                                                       |
; |                           PICTURES                                    |
; |                                                                       |
; =========================================================================

Monitor_switch_display db 1,248

Drive_display       db  11,5 dup (205),219,5 dup (205)

Disk_a_display      db  13,218,11 dup (196),191

Disk_b_display      db  13,179,11 dup (32),179

Disk_c_display      db  13,179,10 dup (32),222,221

Disk_d_display      db  13,179,5 dup (32),9,5 dup (32),179

Disk_e_display      db  13,179,5 dup (32),220,32,248,32,32,32,179

Disk_f_display      db  13,179,5 dup (32),219,5 dup (32),179

Disk_g_display      db  13,192,11 dup (196),217

Tab_display         db  2,222,221

Monitor_off_message db  25
                    db  ' WORKING disk complete.  '

Subttl              Monitor_off

Page

; =========================================================================
; |                                                                       |
; |                            MONITOR OFF                                |
; |                                                                       |
; =========================================================================

Monitor_off     proc    near

                mov     bl,monitor_attribute
                mov     cx,offset monitor_off_message
                mov     dx,0418h
                call    display_message

                mov     al,5

        Pause_1:

                mov     cx,0

        Stall_1_loop:

                loop    stall_1_loop

                dec     al
                jnz     pause_1

        Turn_switch_off:

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_switch_display
                mov     dx,0534h
                call    display_message

                mov     al,1

        Pause_2:

                mov     cx,0

        Stall_2_loop:

                loop    stall_2_loop

                dec     al
                jnz     pause_2

        Clear_monitor_display:

                call    clear_monitor

                mov     al,03h

        Pause_3:

                mov     cx,0

        Stall_3_loop:

                loop    stall_3_loop

                dec     al
                jnz     pause_3

                ret

Monitor_off     endp

Subttl          Drive_on

Page

; =========================================================================
; |                                                                       |
; |                             DRIVE ON                                  |
; |                                                                       |
; =========================================================================

Drive_on        proc    near

                cmp     al,0
                jne     target_drive_on

                mov     dx,0b1fh
                jmp     turn_drive_on

        Target_drive_on:

                mov     dx,0b2dh

        Turn_drive_on:

                mov     bl,picture_on_attribute
                mov     cx,offset drive_display
                call    display_message

                ret

Drive_on        endp

Subttl          Drive_off

Page

; =========================================================================
; |                                                                       |
; |                           DRIVE OFF                                   |
; |                                                                       |
; =========================================================================

Drive_off       proc    near

                cmp     al,0
                jne     target_drive_off

                mov     dx,0b1fh
                jmp     turn_drive_off

        Target_drive_off:

                mov     dx,0b2dh

        Turn_drive_off:

                mov     bl,picture_off_attribute
                mov     cx,offset drive_display
                call    display_message

                ret

Drive_off       endp

Subttl          Disk_on

Page

; =========================================================================
; |                                                                       |
; |                         DISK ON                                       |
; |                                                                       |
; =========================================================================

Disk_on         proc    near

                cmp     al,0
                jne     disk_2_on

                mov     dl,0fh
                jmp     turn_disk_on

        Disk_2_on:

                cmp     al,1
                jne     disk_3_on

                mov     dl,21h
                jmp     turn_disk_on

        Disk_3_on:

                mov     dl,33h

        Turn_disk_on:

                mov     bl,picture_on_attribute
                mov     cx,offset disk_a_display
                mov     dh,0fh
                call    display_message

                mov     bl,picture_on_attribute
                mov     cx,offset disk_b_display
                mov     dh,10h
                call    display_message

                mov     bl,picture_on_attribute
                mov     cx,offset disk_c_display
                mov     dh,11h
                call    display_message

                mov     bl,picture_on_attribute
                mov     cx,offset disk_d_display
                mov     dh,12h
                call    display_message

                mov     bl,picture_on_attribute
                mov     cx,offset disk_e_display
                mov     dh,13h
                call    display_message

                mov     bl,picture_on_attribute
                mov     cx,offset disk_f_display
                mov     dh,14h
                call    display_message

                mov     bl,picture_on_attribute
                mov     cx,offset disk_g_display
                mov     dh,15h
                call    display_message

                ret

Disk_on         endp

Subttl          Drive_off

Page

; =========================================================================
; |                                                                       |
; |                             DISK OFF                                  |
; |                                                                       |
; =========================================================================

Disk_off        proc    near

                cmp     al,0
                jne     disk_2_off

                mov     dl,0fh
                jmp     turn_disk_off

        Disk_2_off:

                cmp     al,1
                jne     disk_3_off

                mov     dl,21h
                jmp     turn_disk_off

        Disk_3_off:

                mov     dl,33h

        Turn_disk_off:

                mov     bl,picture_off_attribute
                mov     cx,offset disk_a_display
                mov     dh,0fh
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_b_display
                mov     dh,10h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_c_display
                mov     dh,11h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_d_display
                mov     dh,12h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_e_display
                mov     dh,13h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_f_display
                mov     dh,14h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_g_display
                mov     dh,15h
                call    display_message

                ret

Disk_off        endp

Subttl          Tab_on

Page

; =========================================================================
; |                                                                       |
; |                            TAB ON                                     |
; |                                                                       |
; =========================================================================

Tab_on          proc    near

                cmp     al,0
                jne     tab_2_on

                mov     dl,1ah
                jmp     turn_tab_on

        Tab_2_on:

                cmp     al,1
                jne     tab_3_on

                mov     dl,2ch
                jmp     turn_tab_on

        Tab_3_on:

                mov     dl,3eh

        Turn_tab_on:

                mov     bl,picture_on_attribute
                mov     cx,offset tab_display
                mov     dh,11h
                call    display_message

                ret

Tab_on          endp

Subttl          Tab_off

Page

; =========================================================================
; |                                                                       |
; |                            TAB OFF                                    |
; |                                                                       |
; =========================================================================

Tab_off         proc    near

                cmp     al,0
                jne     tab_2_off

                mov     dl,1ah
                jmp     turn_tab_off

        Tab_2_off:

                cmp     al,1
                jne     tab_3_off

                mov     dl,2ch
                jmp     turn_tab_off

        Tab_3_off:

                mov     dl,3eh

        Turn_tab_off:

                mov     bl,picture_off_attribute
                mov     cx,offset tab_display
                mov     dh,11h
                call    display_message

                ret

Tab_off         endp

Subttl          Error_on

Page

; =========================================================================
; |                                                                       |
; |                           ERROR ON                                    |
; |                                                                       |
; =========================================================================

Error_on        proc    near

                mov     al,current_drive
                call    drive_on

                cmp     current_error,03h
                jne     error_turn_disk_on

                mov     al,current_disk
                call    tab_on

                jmp     error_on_return

        Error_turn_disk_on:

                mov     al,current_disk
                call    disk_on

        Error_on_return:

                ret

Error_on        endp

Subttl          Error_off

Page

; =========================================================================
; |                                                                       |
; |                           ERROR OFF                                   |
; |                                                                       |
; =========================================================================

Error_off       proc    near

                mov     al,current_drive
                call    drive_off

                cmp     current_error,03h
                jne     error_turn_disk_off

                mov     al,current_disk
                call    tab_off

                jmp     error_off_return

        Error_turn_disk_off:

                mov     al,current_disk
                call    disk_off

        Error_off_return:

                call    clear_error

                ret

Error_off       endp

Subttl          Progress_on

Page

; =========================================================================
; |                                                                       |
; |                            PROGRESS ON                                |
; |                                                                       |
; =========================================================================

Progress_on     proc    near

                ret

Progress_on     endp

Subttl          Progress_off

Page

; =========================================================================
; |                                                                       |
; |                           PROGRESS OFF                                |
; |                                                                       |
; =========================================================================

Progress_off    proc    near

                ret

Progress_off    endp

Copyright_message               db     '(C)opyright 1983 Software '
                                db     'Laboratories Inc.'

Author_message                  db     'Author Cameron L. Wolff'

End_of_data     label   byte

Code_seg        ends

                end
