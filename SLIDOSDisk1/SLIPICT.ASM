Name            SLIPICT

Title           Software_Labs_Inc_dos

Subttl          Picture_sub_routines

Page            60,132

; **************************************************************************
; *                                                                        *
; *              (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                        *
; *                    Author  Cameron L. Wolff                            *
; *                                                                        *
; **************************************************************************

Code_seg        segment public 'code'

                assume cs:code_seg

;
; Externals
;

                extrn display_message:near
                extrn get_any_key:near
                extrn clear_monitor:near
                extrn color:byte
                extrn number_of_drives:byte
                extrn picture_on_attribute:byte
                extrn picture_off_attribute:byte
                extrn monitor_attribute:byte
                extrn current_drive:byte
                extrn current_disk:byte
                extrn current_error:byte
                extrn strike_any_key_message:byte

;
; Public
;

                public sli_picture
                public turn_monitor_on
                public drive_on
                public drive_off
                public disk_on
                public disk_off
                public tab_on
                public tab_off
                public error_on
                public error_off

Subttl          Data

Page

;
; Define word vision picture
;

Monitor_0_display   db  33,201, 27 dup (205), 203, 205,205,205,187

Monitor_1_display   db  33,186,218, 25 dup (196), 191,186,32,32,32,186

Monitor_2_display   db  33,186,179, 25 dup (32),179,186,'IBM',186

Monitor_3_display   db  33,186,179, 25 dup (32),179,186,254,254,254,186

Monitor_4_display   db  33,186,179, 25 dup (32),179,186,32,32,32,186

Monitor_5_display   db  33,186,179, 25 dup (32),179,186,32,248,32,186

Monitor_6_display   db  33,186,179, 25 dup (32),179,186,32,248,32,186

Monitor_7_display   db  33,186,192, 25 dup (196), 217,186,32,32,32,186

Monitor_8_display   db  33,200, 27 dup (205), 202,205,205,205,188

Chasis_0_display    db  43,218, 41 dup (196), 191

Chasis_1_display    db  43,179,32,32,'IBM',6 dup (32),201,13 dup (205)
                    db     203,13 dup (205),187,32,179

Chasis_2_display_1 db  43,179,32,32,254,254,254,6 dup (32),186,32,5 dup (205)
                   db     219,5 dup (205),32,186,13 dup (32),186,32,179

Chasis_2_display_2 db  43,179,32,32,254,254,254,6 dup (32),186,32,5 dup (205)
                   db     219,5 dup (205),32,186,32,5 dup (205),219
                   db     5 dup (205),32,186,32,179

Chasis_3_display    db  43,179,32,9 dup (186),32,200,13 dup (205)
                    db     202,13 dup (205),188,32,179

Chasis_4_display    db  43,192,41 dup (196),217

Disk_0_display      db  49,218,11 dup (196),191,32,32,32,32,32
                    db     218,11 dup (196),191,32,32,32,32,32
                    db     218,11 dup (196),191

Disk_1_display      db  49,179,11 dup (32),179,32,32,32,32,32
                    db     179,11 dup (32),179,32,32,32,32,32
                    db     179,11 dup (32),179

Disk_2_display      db  49,179,10 dup (32),222,221,32,32,32,32,32
                    db     179,10 dup (32),222,221,32,32,32,32,32
                    db     179,10 dup (32),222,221

Disk_3_display      db  49,179,5 dup (32),9,5 dup (32),179,32,32,32,32,32
                    db     179,5 dup (32),9,5 dup (32),179,32,32,32,32,32
                    db     179,5 dup (32),9,5 dup (32),179
 
Disk_4_display  db  49,179,5 dup (32),220,32,248,32,32,32,179,32,32,32,32,32
                db     179,5 dup (32),220,32,248,32,32,32,179,32,32,32,32,32
                db     179,5 dup (32),220,32,248,32,32,32,179

Disk_5_display      db  49,179,5 dup (32),219,5 dup (32),179,32,32,32,32,32
                    db     179,5 dup (32),219,5 dup (32),179,32,32,32,32,32
                    db     179,5 dup (32),219,5 dup (32),179

Disk_6_display      db  49,192,11 dup (196),217,32,32,32,32,32
                    db     192,11 dup (196),217,32,32,32,32,32
                    db     192,11 dup (196),217

Disks_message       db  48,'MASTER Disk       IBM DOS Disk      WORKING Disk'

Sli_0_message       db  25,'  Software Laboratories  '

Sli_1_message       db  25,'      Incorporated       '

Sli_2_message       db  25,'    (C)opyright 1983     '

Monitor_switch_display  db  1,248

; Special prompt messages

Drive_display       db  11,5 dup (205),219,5 dup (205)

Disk_a_display      db  13,218,11 dup (196),191

Disk_b_display      db  13,179,11 dup (32),179

Disk_c_display      db  13,179,10 dup (32),222,221

Disk_d_display      db  13,179,5 dup (32),9,5 dup (32),179

Disk_e_display      db  13,179,5 dup (32),220,32,248,32,32,32,179

Disk_f_display      db  13,179,5 dup (32),219,5 dup (32),179

Disk_g_display      db  13,192,11 dup (196),217

Tab_display         db  2,222,221

Subttl          Sli_picture

Page

; ==========================================================================
; |                                                                        |
; |                             SLI PICTURE                                |
; |                                                                        |
; |      Display a picture of a IBM computer (monitor and main chasis)     |
; |      along with three disk labeled, Master, IBM DOS Disk, Working Disk |
; |                                                                        |
; |      Input:                                                            |
; |             AL - 0 monochrome display                                  |
; |             AL - 1 color display                                       |
; |                                                                        |
; ==========================================================================

Sli_picture     proc near

; Display IBM monitor

        Display_ibm_monitor:

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_0_display
                mov     dx,0016h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_1_display
                mov     dx,0116h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_2_display
                mov     dx,0216h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_3_display
                mov     dx,0316h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_4_display
                mov     dx,0416h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_5_display
                mov     dx,0516h
                call    display_message

                cmp     color,1
                jne     monitor_continue

                mov     bl,picture_off_attribute
                or      bl,08h
                mov     cx,offset monitor_switch_display
                mov     dx,0534h
                call    display_message

        Monitor_continue:

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_6_display
                mov     dx,0616h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_7_display
                mov     dx,0716h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset monitor_8_display
                mov     dx,0816h
                call    display_message

; Display chasis of IBM computer

        Display_ibm_chasis:

                mov     bl,picture_off_attribute
                mov     cx,offset chasis_0_display
                mov     dx,0911h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset chasis_1_display
                mov     dx,0a11h
                call    display_message

                cmp     number_of_drives,1
                jne     display_two_drives

                mov     bl,picture_off_attribute
                mov     cx,offset chasis_2_display_1
                mov     dx,0b11h
                call    display_message

                jmp     chasis_continue

        Display_two_drives:

                mov     bl,picture_off_attribute
                mov     cx,offset chasis_2_display_2
                mov     dx,0b11h
                call    display_message

        Chasis_continue:

                mov     bl,picture_off_attribute
                mov     cx,offset chasis_3_display
                mov     dx,0c11h
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset chasis_4_display
                mov     dx,0d11h
                call    display_message

; Display 3 disks

        Display_3_disks:

                mov     bl,picture_off_attribute
                mov     cx,offset disk_0_display
                mov     dx,0f0fh
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_1_display
                mov     dx,100fh
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_2_display
                mov     dx,110fh
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_3_display
                mov     dx,120fh
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_4_display
                mov     dx,130fh
                call    display_message

                mov     bl,picture_off_attribute
                mov     cx,offset disk_5_display
                mov     dx,140fh
                call    display_message
 
                mov     bl,picture_off_attribute
                mov     cx,offset disk_6_display
                mov     dx,150fh
                call    display_message

; Display disk message

                mov     bl,picture_off_attribute
                mov     cx,offset disks_message
                mov     dx,1610h
                call    display_message

                ret

Sli_picture     endp

Subttl          Turn_monitor_on

Page

; =========================================================================
; |                                                                       |
; |                       TURN MONITOR ON                                 |
; |                                                                       |
; =========================================================================

Turn_monitor_on proc    near

; Turn display on then display Company Message

        Display_monitor_switch:

                mov     al,3

        Pause_1:

                mov     cx,0

        Stall_1_loop:

                loop    stall_1_loop

                dec     al
                jnz     pause_1

        Turn_switch_on:

                mov     bl,picture_off_attribute
                or      bl,08h
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

        Display_logo:

                mov     bl,monitor_attribute
                mov     cx,offset sli_0_message
                mov     dx,0218h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset sli_1_message
                mov     dx,0418h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset sli_2_message
                mov     dx,0618h
                call    display_message

                mov     al,05h

        Pause_3:

                mov     cx,0

        Stall_3_loop:

                loop    stall_3_loop

                dec     al
                jnz     pause_3

                ret

Turn_monitor_on endp

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

                mov     bl,monitor_attribute
                mov     cx,offset strike_any_key_message
                mov     dx,0418h
                call    display_message

                mov     al,current_drive
                call    drive_on

                cmp     current_error,03h
                jne     error_disk_on

                mov     al,current_disk
                call    tab_on

                jmp     error_on_return

        Error_disk_on:

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

                call    clear_monitor

                mov     al,current_drive
                call    drive_off

                cmp     current_error,03h
                jne     error_disk_off

                mov     al,current_disk
                call    tab_off

                jmp     error_off_return

        Error_disk_off:

                mov     al,current_disk
                call    disk_off
                
        Error_off_return:

                ret

Error_off       endp

Code_seg        ends

                end

