Name            SLIBOSS

Title           Software_labs_inc_command

Subttl          SLI_Command

Page 60,132

; *************************************************************************
; *                                                                       *
; *             (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

Code_seg        segment public 'code'

                assume cs:code_seg

                org   100h

;
; Include external data file
;

                include c:slidata.inc

;
; Externals procedures
;

                extrn   format_work_copy:near
                extrn   transfer_master_files:near
                extrn   verify_master:near
                extrn   verify_work:near
                extrn   monitor_off:near
                extrn   drive_on:near
                extrn   drive_off:near
                extrn   disk_on:near
                extrn   disk_off:near
                extrn   tab_on:near
                extrn   tab_off:near
                extrn   error_on:near
                extrn   error_off:near
                extrn   progress_on:near
                extrn   progress_off:near

;
; Public procedures
;

                public  get_any_key
                public  display_message
                public  clear_monitor
                public  disk_failure
                public  master_failure
                public  work_failure
                public  function_key
                public  clear_error
                public  master_prompt
                public  work_prompt
                public  ibm_dos_prompt
                public  master_write_protect_prompt          

Page

; =========================================================================
; *                                                                       *
; *                          SLI COMMAND                                  *
; *                                                                       *
; *      Dos is a stub to show transfer of control from wvdos.            *
; *                                                                       *
; =========================================================================

Sli_command     proc    far

                cli

; Set up segment registers and stack pointer

                mov     ax,cs
                mov     ds,ax
                mov     es,ax
                mov     ss,ax
                xor     ax,ax
                mov     sp,100h

                sti

; Get system cofiguration and intialize screen display

                call    initial_display

; Protect wv command.com file

                mov      al,source_drive
                mov      current_drive,al
                mov      current_disk,0

                jmp      protect_command_file_operation

; Hide COMMAND.COM file

        Protect_command_file_prompt:

                call     master_prompt

        Protect_command_file_operation:

                call     verify_master

                jc       protect_command_file_prompt

                call     protect_command_file

                jc       protect_command_file_prompt

; Verify MASTER is write protected

        Write_protect_prompt:

                call     master_write_protect_prompt

        Write_protect_check:

                call     verify_master

                jc       write_protect_prompt

                call     write_protect_master_check

                jc       write_protect_prompt

; Format working disk

        Format_work_copy_loop:

                call     format_work_copy

; Transfer IBM DOS files and MASTER files

                call     transfer_master_files

                jc       format_work_copy_loop

; Workcopy was successfully copied

        Workcopy_success:

                mov      al,source_drive
                mov      current_drive,al
                mov      current_disk,2

                call     work_prompt

                call     verify_work

                jc       workcopy_success

                call     monitor_off

                mov      ax,0600h
                mov      bh,07h
                mov      cx,0
                mov      dx,184fh
                int      10h

                int      19h

Sli_command     endp

Subttl          Initial_display

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          INITIAL DISPLAY                             |
; |                                                                      |
; |      Get system configuration set by SLIDOS and set color and disk   |
; |      parameters accordly. Then display initial screen.               |
; |                                                                      |
; ------------------------------------------------------------------------

Initial_display proc    near

                cli

                push    es

                mov     ax,0
                mov     es,ax

; Get number of drives and color status passed by SLIDOS

                mov     bx,100h
                mov     al,es:[bx]
                mov     number_of_drives,al
                inc     bx
                mov     al,es:[bx]
                mov     color,al

; Set critical error handling vector

                mov     bx,90h
                mov     word ptr es:[bx],offset dos_error_handler
                add     bx,2
                mov     es:[bx],cs

                pop     es

                sti

; Set up general dta

                mov     ax,offset end_of_data
                mov     cl,4
                shr     ax,cl
                inc     ax
                mov     bx,cs
                add     ax,bx
                mov     general_dta_seg,ax

; Determine source and destination drives

                cmp     number_of_drives,0
                je      one_drive

                mov     source_drive,0
                mov     destination_drive,1
                jmp     set_up_screen

        One_drive:

                mov     source_drive,0
                mov     destination_drive,0

        Set_up_screen:

                cmp     color,1
                je      color_monitor

; Black and white mode

                mov     picture_on_attribute,87h
                mov     picture_off_attribute,07h
                mov     monitor_attribute,07h
                mov     error_attribute,70h

                jmp     initial_display_return

; Color mode

        Color_monitor:

                mov     picture_on_attribute,83h
                mov     picture_off_attribute,03h
                mov     monitor_attribute,02h
                mov     error_attribute,47h

        Initial_display_return:

                ret

Initial_display endp

Subttl          Get_any_key

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           GET ANY KEY                                 |
; |                                                                       |
; |        Gets a key from the key board after flushing it first          |
; |                                                                       |
; |        AH - scan code  AL - ascii code                                |
; |                                                                       |
; -------------------------------------------------------------------------

Get_any_key     proc    near

                pushf

        Flush_buffer:

                mov     ah,1
                int     16h

                jz      get_next_key

                mov     ah,0
                int     16h

                jmp     flush_buffer

        Get_next_key:

                mov     ah,0
                int     16h

                popf

                ret

Get_any_key     endp

Subttl          Function_key

Page

; =======================================================================
; |                                                                     |
; |                            FUNCTION KEY                             |
; |                                                                     |
; |       Get response from user. If F4, set carry if F2, clear carry   |
; |       Do not exit unless F2 or F4 entered                           |
; |                                                                     |
; =======================================================================

Function_key    proc    near

                clc

        Get_function_key:

                call    get_any_key

                cmp     ah,3ch             ; F2
                je      function_key_return

                cmp     ah,3eh             ; F4
                jne     get_function_key

                stc

        Function_key_return:

                ret

Function_key    endp

Subttl          Display_message

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                          DISPLAY MESSAGE                             |
; |                                                                      |
; |  Display message driver. First byte is length of string to dispaly   |
; |                                                                      |
; |              Input:                                                  |
; |                      BL    - attribute                               |
; |                      CS:CX - contains address of message             |
; |                      DX    - position                                |
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
                mov     bh,7
                mov     cx,0218h
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
                mov     bh,7
                mov     cx,1800h
                mov     dx,184fh
                int     10h

                pop     ax
                popf

                ret

Clear_error     endp

Subttl          Protect_command_file

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           PROTECT COMMAND FILE                        |
; |                                                                       |
; -------------------------------------------------------------------------

Protect_command_file proc near

                push    es

                mov     ax,general_dta_seg
                mov     es,ax

                mov     disk_retry,3

        Read_directory_loop:

                mov     ax,0201h
                mov     cx,0004h
                mov     dx,0
                mov     bx,0
                int     13h

                jnc     set_command_to_invisible

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     read_directory_loop
 
                call    disk_failure

                call    verify_master
                jnc     read_directory_loop_continue

                stc

                jmp     protect_command_file_return

        Read_directory_loop_continue:

                mov     disk_retry,3
                jmp     read_directory_loop

        Set_command_to_invisible:

                mov     byte ptr es:[bx+11+32],06h

                mov     disk_retry,1

        Write_directory_loop:

                mov     ax,0301h
                mov     cx,0004h
                mov     dx,0
                mov     bx,0
                int     13h

                jnc     protect_command_file_return

                mov     current_error,ah

                mov     ah,0
                int     13h

                dec     disk_retry
                jnz     write_directory_loop

                call    disk_failure

                call    verify_master
                jnc     write_directory_loop_continue

                stc

                jmp     protect_command_file_return

        Write_directory_loop_continue:

                mov     disk_retry,3

                jmp     read_directory_loop

        Protect_command_file_return:

                pop     es

                ret

Protect_command_file endp

Subttl          Write_protect_master_check

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                     WRITE PROTECT MASTER CHECK                       |
; |                                                                      |
; |                 Checks to see if MASTER is write protectd            |
; |                                                                      |
; ------------------------------------------------------------------------

Write_protect_master_check proc near

                push    es

                mov     ax,general_dta_seg
                mov     es,ax

; Read in a sector and try to write it back to verify write protect tab

                mov     disk_retry,3

        Protect_read_loop:

                mov     ax,0201h
                mov     cx,2001h
                mov     dx,0000h
                mov     bx,0
                int     13h

                jnc     check_write_protect

                mov     current_error,ah

                mov     ax,0
                int     13h

                dec     disk_retry
                jnz     protect_read_loop

                call    disk_failure

                call    verify_master

                jnc     protect_read_loop_continue

                jmp     write_protect_master_return

        Protect_read_loop_continue:

                mov     disk_retry,3

                jmp     protect_read_loop

        Check_write_protect:

                mov     disk_retry,1

         Protect_write_loop:

                mov     ax,0301h
                mov     cx,2001h
                mov     dx,0000h
                mov     bx,0
                int     13h

                jnc     disk_not_write_protected

                mov     current_error,ah

                mov     ax,0
                int     13h

                mov     ah,current_error
                and     ah,03h
                cmp     ah,03h
                je      disk_write_protected

                dec     disk_retry
                jnz     protect_write_loop

                call    disk_failure

                call    verify_master

                jnc     protect_write_loop_continue

                stc

                jmp     write_protect_master_return

        Protect_write_loop_continue:

                mov     disk_retry,1

                jmp     protect_read_loop

        Disk_not_write_protected:

                mov     bl,error_attribute
                mov     cx,offset not_write_protected_message
                mov     dx,18ffh
                call    display_message

                stc

                jmp     write_protect_master_return

        Disk_write_protected:

                clc

        Write_protect_master_return:

                pop     es

                ret

Write_protect_master_check endp

Subttl          Disk_failure

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                                DISK FAILURE                          |
; |                                                                      |
; |         Input:                                                       |
; |               Current_error   -  error code                          |
; |               Current_disk    -  0,master 1,IBM Dos 2,working        |
; |               Current_drive   -  0,source 0,1,target                 |
; |                      If Word Vison Master and fatal error prompt     |
; |                      for DOS and Reboot                              |
; |                                                                      |
; ------------------------------------------------------------------------

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
                jne     not_master_diskette

                call    master_failure

        Not_master_diskette:

                mov     cx,offset damaged_diskette_message

        Display_disk_error:

                push    cx

                call    clear_monitor

                mov     bl,monitor_attribute
                mov     cx,offset strike_any_key_message
                mov     dx,0418h
                call    display_message

                call    error_on

                pop     cx

                mov     bl,error_attribute
                mov     dx,18ffh
                call    display_message

                call    get_any_key

                call    clear_monitor

                call    error_off

                mov     current_error,0

                ret

Disk_failure    endp

Subttl          Master_failure

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          MASTER FAILURE                               |
; |                                                                       |
; -------------------------------------------------------------------------

Master_failure  proc    near

                call    clear_monitor

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,1

                mov     bl,error_attribute
                mov     cx,offset fatal_master_message
                mov     dx,18ffh
                call    display_message

                jmp     failure_dos_prompt

        Failure_dos_prompt:

                call    ibm_dos_prompt

                call    verify_ibm

                jc      failure_dos_prompt

                mov     ax,0600h
                mov     bh,07h
                mov     cx,0
                mov     dx,184fh
                int     10h

                int     19h

Master_failure  endp

Subttl          Work_failure

Page

; =========================================================================
; |                                                                       |
; |                           WORK FAILURE                                |
; |                                                                       |
; =========================================================================

Work_failure    proc     near

                call     clear_monitor

                mov      al,source_drive
                mov      current_drive,al
                mov      current_disk,0

                mov      bl,error_attribute
                mov      cx,offset fatal_work_message
                mov      dx,18ffh
                call     display_message

        Failure_master_prompt:

                call     master_prompt

                call     verify_master

                jc       failure_master_prompt

                mov    ax,0600h
                mov    bh,07h
                mov    cx,0
                mov    dx,184fh
                int    10h

                int    19h

Work_failure    endp

Subttl          Dos_error_handler

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $
; $                           DOS ERROR HANDLER                           $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Dos_error_handler proc near

                push    bx
                push    cx
                push    dx
                push    bp
                push    si
                push    di
                push    ds
                push    es

                sti

                mov     ax,cs
                mov     ds,ax

                test    ah,10000000b
                jz      disk_error

                jmp     dos_error_return

; Disk error inform user which one

        Disk_error:

                and    di,00ffh

                cmp    di,0
                je     write_protect_error

                cmp    di,2
                je     drive_not_ready_error

                cmp    di,4
                je     cant_fix_error

                cmp    di,6
                je     cant_fix_error

                cmp    di,8
                je     cant_fix_error

                cmp    di,0ah
                je     cant_fix_error

                jmp    cant_fix_error

        Write_protect_error:

                mov    current_error,3

                mov    cx,offset write_protect_message
                call   fix_disk_error
                mov    al,1

                jmp    dos_error_return

         Drive_not_ready_error:

                mov    current_error,80h

                mov    cx,offset drive_not_ready_message
                call   fix_disk_error
                mov    al,1

                jmp    dos_error_return

        Cant_fix_error:

                 cmp   current_disk,0
                 jne   not_master_failure

                 call  master_failure

        Not_master_failure:

                 call  work_failure

        Dos_error_return:

                mov     current_error,0

                pop     es
                pop     ds
                pop     di
                pop     si
                pop     bp
                pop     dx
                pop     cx
                pop     bx

                iret

Dos_error_handler endp

Subttl          Fix_disk_error

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             FIX DISK ERROR                            |
; |                                                                       |
; |      Input:                                                           |
; |             CS:CX offset of message to display                        |
; |                                                                       |
; -------------------------------------------------------------------------

Fix_disk_error  proc    near

                push    cx

                call    clear_monitor

                mov     bl,monitor_attribute
                mov     cx,offset strike_any_key_message
                mov     dx,0418h
                call    display_message

                call    error_on

                pop     cx

                mov     bl,error_attribute
                mov     dx,18ffh
                call    display_message

                call    get_any_key

                call    clear_monitor

                call    error_off

                ret

Fix_disk_error  endp

Subttl          Work_prompt

Page

; =========================================================================
; |                                                                       |
; |                           WORK PROMPT                                 |
; |                                                                       |
; =========================================================================

Work_prompt     proc    near

                mov      al,current_drive
                add      al,'A'
                mov      working_drive,al

                mov      bl,monitor_attribute
                mov      cx,offset working_copy_message_1
                mov      dx,0218h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset working_copy_message_2
                mov      dx,0418h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset strike_any_key_message
                mov      dx,0618h
                call     display_message

                mov      al,current_drive
                call     drive_on

                mov      al,current_disk
                call     disk_on

                call     get_any_key

                call     clear_monitor

                mov      al,current_drive
                call     drive_off

                mov      al,current_disk
                call     disk_off

                call     clear_error

                ret

Work_prompt     endp

Subttl          Master_prompt

Page

; ========================================================================
; |                                                                      |
; |                             MASTER PROMPT                            |
; |                                                                      |
; ========================================================================

Master_prompt   proc    near

                mov      bl,monitor_attribute
                mov      cx,offset insert_master_message_1
                mov      dx,0218h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset insert_master_message_2
                mov      dx,0418h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset strike_any_key_message
                mov      dx,0618h
                call     display_message

                mov      al,current_drive
                call     drive_on

                mov      al,current_disk
                call     disk_on

                call     get_any_key

                call     clear_monitor

                mov      al,current_drive
                call     drive_off

                mov      al,current_disk
                call     disk_off

                call     clear_error

                ret

Master_prompt   endp

Subttl          Ibm_dos_prompt

Page

; =========================================================================
; |                                                                       |
; |                         IBM DOS PROMPT                                |
; |                                                                       |
; =========================================================================

Ibm_dos_prompt  proc    near

                mov      bl,monitor_attribute
                mov      cx,offset insert_ibm_message_1
                mov      dx,0218h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset insert_ibm_message_2
                mov      dx,0418h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset strike_any_key_message
                mov      dx,0618h
                call     display_message

                mov      al,current_drive
                call     drive_on

                mov      al,current_disk
                call     disk_on

                call     get_any_key

                call     clear_monitor

                mov      al,current_drive
                call     drive_off

                mov      al,current_disk
                call     disk_off

                call     clear_error

                ret

Ibm_dos_prompt  endp

Subttl          Master_write_protect_prompt

Page

; =========================================================================
; |                                                                       |
; |                    MASTER WRITE PROTECT PROMPT                        |
; |                                                                       |
; =========================================================================

Master_write_protect_prompt proc near

                mov      bl,monitor_attribute
                mov      cx,offset please_write_protect_message_1
                mov      dx,0218h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset please_write_protect_message_2
                mov      dx,0418h
                call     display_message

                mov      bl,monitor_attribute
                mov      cx,offset strike_any_key_message
                mov      dx,0618h
                call     display_message

                mov      al,current_drive
                call     drive_on

                mov      al,current_disk
                call     tab_on

                call     get_any_key

                call     clear_monitor

                mov      al,current_drive
                call     drive_off

                mov      al,current_disk
                call     tab_off

                call     clear_error

                ret

Master_write_protect_prompt endp

Code_seg        ends

                end     sli_command
