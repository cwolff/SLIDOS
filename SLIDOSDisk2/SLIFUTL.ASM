Name            SLIFUTL

Title           Software_Labs_Inc_command

Subttl          File_utility

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

                extrn  display_message:near
                extrn  get_any_key:near
                extrn  clear_monitor:near
                extrn  disk_failure:near
                extrn  search_first_entry:near
                extrn  search_next_entry:near
                extrn  open_file:near
                extrn  read_driver:near
                extrn  create_file:near
                extrn  write_driver:near
                extrn  close_file:near
                extrn  read_boot:near
                extrn  write_boot:near
                extrn  master_failure:near
                extrn  work_failure:near
                extrn  master_prompt:near
                extrn  ibm_dos_prompt:near
                extrn  work_prompt:near

;
; Public
;

                public   verify_master
                public   verify_work
                public   verify_ibm
                public   read_ibm_files
                public   write_ibm_files
                public   transfer_master_files
                public   check_disk

Subttl          Verify_master

Page

; =========================================================================
; |                                                                       |
; |                            VERIFY MASTER                              |
; |                                                                       |
; |                                                                       |
; =========================================================================

Verify_master   proc near

                mov     si,offset sli_dos_name
                mov     di,00h
                call    check_disk

                jnc     verify_master_return

                mov     bl,error_attribute
                mov     cx,offset not_master_message
                mov     dx,18ffh
                call    display_message

                stc

        Verify_master_return:

                ret

Verify_master   endp

Subttl          Verify_work

Page

; ========================================================================
; |                                                                      |
; |                              VERIFY WORK                             |
; |                                                                      |
; |            Make sure its not a work vision master diskette           |
; |                                                                      |
; |          Output:                                                     |
; |                 CY - 1 blank diskette                                |
; |                                                                      |
; ========================================================================

Verify_work     proc near

                mov     si,offset sli_dos_name
                mov     di,00h
                call    check_disk

                jc      working_copy

                mov     bl,error_attribute
                mov     cx,offset not_working_message
                mov     dx,18ffh
                call    display_message

                stc

                jmp     verify_work_return

        Working_copy:

                clc

        Verify_work_return:

                ret

Verify_work     endp

Subttl          Verify_ibm

Page

; =========================================================================
; |                                                                       |
; |                          VERIFY IBM                                   |
; |                                                                       |
; |                  Verify that is a IBM DOS diskette                    |
; |                                                                       |
; =========================================================================

Verify_ibm      proc    near

                mov     si,offset ibm_bio_name
                mov     di,0
                call    check_disk

                jc      not_ibm_disk

                mov     si,offset ibm_dos_name
                mov     di,20h
                call    check_disk

                jc      not_ibm_disk

                mov     al,0
                mov     si,offset command_name              
                call    search_first_entry

                jnc     verify_ibm_return

        Not_ibm_disk:

                mov     bl,error_attribute
                mov     cx,offset not_ibm_message
                mov     dx,18ffh
                call    display_message

                stc

        Verify_ibm_return:

                ret

Verify_ibm      endp

Subttl          Check_disk

Page

; =========================================================================
; |                                                                       |
; |                             CHECK DISK                                |
; |                                                                       |
; |          Read in directory and verify that the file listed is a       |
; |          file specified by the address of cs:si                       |
; |                                                                       |
; |         Input:                                                        |
; |                CS:[SI] address of file to match                       |
; |                DI offset into DTA for compare                         |
; |                                                                       |
; |         Ouput:                                                        |
; |                CY - 0 file was found                                  |
; |                CY - 1 file was not found                              |
; |                                                                       |
; =========================================================================

Check_disk      proc    near

                push    es

                mov     ax,general_dta_seg
                mov     es,ax

                mov     disk_retry,3

        Check_disk_loop:

                mov     ax,0201h
                mov     cx,0004h
                mov     dh,0
                mov     dl,current_drive
                mov     bx,0
                int     13h

                jnc     convert_to_lower_case

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     check_disk_loop

                call    disk_failure

                mov     disk_retry,3
                jmp     check_disk_loop

        Convert_to_lower_case:

                push    di

                mov     cx,0bh

        Convert_loop:

                or      byte ptr es:[di],20h
                inc     di

                loop    convert_loop

                cld

                pop     di

                mov     cx,0bh

                repz    cmpsb

                jz      check_disk_return

                stc

        Check_disk_return:

                pop     es

                ret

Check_disk      endp

Subttl          Read_ibm_files

Page

; =========================================================================
; |                                                                       |
; |                             READ IBM FILES                            |
; |                                                                       |
; |                Read ibmbio.com ibmdos.com command.com                 |
; |                                                                       |
; =========================================================================

Read_ibm_files  proc    near

                push    ds
                push    es

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,1

                mov     dx,general_dta_seg
                add     dx,40h
                mov     file_1_dta,dx

        Read_ibm_files_prompt:

                call    ibm_dos_prompt

                call    verify_ibm

                jc      read_ibm_files_prompt

; Display reading message

        Read_ibm_error_loop:

                mov     bl,monitor_attribute
                mov     cx,offset reading_ibm_message_1
                mov     dx,0318h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset reading_ibm_message_2
                mov     dx,0518h
                call    display_message

; Process boot

                call    read_boot

; Process IBMBIO.COM

                mov     al,1
                mov     dl,1
                mov     si,offset ibm_bio_name
                call    open_file

                jc      fatal_ibm_read_error

                mov     al,1
                call    read_driver

                jc      fatal_ibm_read_error

; Process IBMDOS.COM

                mov     al,1
                mov     dl,2
                mov     si,offset ibm_dos_name
                call    open_file

                jc      fatal_ibm_read_error

                mov     al,2
                call    read_driver

                jc      fatal_ibm_read_error

; Process COMMAND.COM

                mov     al,0
                mov     dl,3
                mov     si,offset command_name
                call    open_file

                jc      fatal_ibm_read_error

                mov     al,3
                call    read_driver

                jc      fatal_ibm_read_error

                jmp     read_ibm_files_return

        Fatal_ibm_read_error:

                mov     bl,error_attribute
                mov     cx,offset fatal_ibm_message
                mov     dx,18ffh
                call    display_message

                call    clear_monitor

                jmp     read_ibm_files

        Read_ibm_files_return:

                call    clear_monitor

                pop     es
                pop     ds

                ret

Read_ibm_files  endp

Subttl          Write_ibm_files

Page

; ========================================================================
; |                                                                      |
; |                          WRITE IBM FILES                             |
; |                                                                      |
; |                Write ibmbio.com ibm.com command.com                  |
; |                                                                      |
; ========================================================================

Write_ibm_files proc    near

                push    ds
                push    es

                mov     al,destination_drive
                mov     current_drive,al
                mov     current_disk,2

                mov     al,source_drive
                cmp     al,destination_drive
                jne     verify_working_disk

        Ibm_write_prompt:

                call    work_prompt

        Verify_working_disk:

                call    verify_work

                jc      ibm_write_prompt

        Verify_working_operation:

                mov     bl,monitor_attribute
                mov     cx,offset writing_ibm_message_1
                mov     dx,0318h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset writing_ibm_message_2
                mov     dx,0518h
                call    display_message

; Process boot track

                call     write_boot

                jnc      write_com_files

                jmp      write_ibm_files_return

; Process IBMBIO.COM

        Write_com_files:

                mov     al,1
                mov     dl,1
                call    create_file

                jc      fatal_ibm_write_error

                mov     al,1
                call    write_driver

                jc      fatal_ibm_write_error

                mov     dl,1
                call    close_file

                jc      fatal_ibm_write_error

 ; Process IBMDOS.COM

                mov     al,1
                mov     dl,2
                call    create_file

                jc      fatal_ibm_write_error

                mov     al,2
                call    write_driver

                jc      fatal_ibm_write_error

                mov     dl,2
                call    close_file

                jc      fatal_ibm_write_error

; Process COMMAND.COM

                mov     al,0
                mov     dl,3
                call    create_file

                jc      fatal_ibm_write_error

                mov     al,3
                call    write_driver

                jc      fatal_ibm_write_error

                mov     dl,3
                call    close_file

                jc      fatal_ibm_write_error

                clc
                jmp     write_ibm_files_return

        Fatal_ibm_write_error:

                mov     bl,error_attribute
                mov     cx,offset fatal_work_message
                mov     dx,18ffh
                call    display_message

                stc

        Write_ibm_files_return:

                call    clear_monitor

                pop     es
                pop     ds
 
                ret

Write_ibm_files endp

Subttl          Transfer_word_vision_files

Page

; =========================================================================
; |                                                                       |
; |                         TRANSFER MASTER FILES                         |
; |                                                                       |
; |                Transfer files form Master to working copy             |
; |                                                                       |
; =========================================================================

Transfer_master_files proc  near

                mov     dx,general_dta_seg
                add     dx,20h
                mov     file_1_dta,dx

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,0

        Master_read_prompt:

                call    master_prompt

                call    verify_master

                jc      master_read_prompt

                mov     al,1
                mov     si,offset any_file_name
                call    search_first_entry

                jnc     open_first_file

                jmp     fatal_read_transfer_error

        Open_first_file:

                mov     al,0
                mov     dl,1
                mov     si,0
                call    open_file

                jnc     first_file_opened

                jmp     fatal_read_transfer_error

      First_file_opened:

                mov     ax,0100h      ; begin first search

; Load up file control blocks to read

        Transfer_file_loop:

                call    load_fcb

                jnc     successful_load

                jmp     fatal_read_transfer_error

        Successful_load:

                cmp     al,0
                jne     more_to_transfer

                jmp     successful_transfer

        More_to_transfer:

                push    ax

                mov     bl,monitor_attribute
                mov     cx,offset reading_master_message_1
                mov     dx,0318h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset reading_master_message_2
                mov     dx,0518h
                call    display_message

                call    read_master

                jnc     read_transfer_continue

                jmp     fatal_read_transfer_error

        Read_transfer_continue:

                call    clear_monitor

                pop     ax

                jnc     more_to_write

                jmp     transfer_return

; Determine if working prompt necessary

        More_to_write:

                push    ax

                mov     al,destination_drive
                mov     current_drive,al
                mov     current_disk,2

                mov     al,source_drive
                cmp     al,destination_drive
                jne     no_working_prompt_neccessary

        Work_write_prompt:

                call    work_prompt

        No_working_prompt_neccessary:

                call    verify_work

                jc      work_write_prompt

                pop     ax
                push    ax

                mov     bl,monitor_attribute
                mov     cx,offset writing_working_message_1
                mov     dx,0318h
                call    display_message

                mov     bl,monitor_attribute
                mov     cx,offset writing_working_message_2
                mov     dx,0518h
                call    display_message

                call    write_working

                jnc     write_transfer_continue

                jmp     fatal_write_transfer_error

        Write_transfer_continue:

                call    clear_monitor

                pop     ax

                jnc     successful_write_operation

                jmp     transfer_return

; Determine if master prompt required

        Successful_write_operation:

                push    ax

                mov     al,source_drive
                mov     current_drive,al
                mov     current_disk,0

                mov     al,source_drive
                cmp     al,destination_drive
                jne     no_master_prompt_neccessary

         Master_read_prompt_1:

                call    master_prompt

        No_master_prompt_neccessary:

                call    verify_master

                jc      master_read_prompt_1

; On 1 drive system dos becomes confused open file to clear things up

                mov     al,0
                mov     dl,1
                mov     si,0
                call    open_file

                pop     ax

                jmp     transfer_file_loop

        Fatal_read_transfer_error:

                call    master_failure

        Fatal_write_transfer_error:

                mov     bl,error_attribute
                mov     cx,offset fatal_work_message
                mov     dx,18ffh
                call    display_message

                stc

                jmp     transfer_return

        Successful_transfer:

                clc

        Transfer_return:

                call    clear_monitor

                ret

Transfer_master_files endp

Subttl          Read_master

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           READ MASTER                                 |
; |                                                                       |
; |              AL - number of files to read                             |
; |                                                                       |
; -------------------------------------------------------------------------

Read_master     proc    near

; Process first file

                cmp     al,1
                jae     read_first_file

                clc
                jmp     read_master_return

        Read_first_file:

                push    ax

                mov     al,1
                call    read_driver

                pop     ax

                jc      fatal_master_read_error

; Process second file

                cmp     al,2
                jae     read_second_file    

                clc
                jmp     read_master_return

        Read_second_file:

                push    ax

                mov     al,2
                call    read_driver

                pop     ax

                jc      fatal_master_read_error

; Process third file

                cmp     al,3
                jae     read_3_file

                clc
                jmp     read_master_return

        Read_3_file:

                mov     al,3
                call    read_driver

                jc      fatal_master_read_error

                jmp     read_master_return

        Fatal_master_read_error:

                stc

        Read_master_return:

                call    clear_monitor

                ret

Read_master     endp

Subttl          Write_working

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          WRITE WORKING                                |
; |                                                                       |
; |            AL - number of files to write                              |
; |                                                                       |
; -------------------------------------------------------------------------

Write_working   proc   near

; Process first file

                cmp     al,1
                jae     write_1_file

                clc
                jmp     write_working_return

        Write_1_file:

                push    ax

                mov     al,0
                mov     dl,1
                call    create_file

                pop     ax

                jc      fatal_working_error

                push    ax

                mov     al,1
                call    write_driver

                pop     ax

                jc      fatal_working_error

                push    ax

                mov     dl,1
                call    close_file

                pop     ax

                jc      fatal_working_error

 ; Process second file

                cmp     al,2
                jae     write_2_file

                clc
                jmp     write_working_return

        Write_2_file:

                push    ax

                mov     al,0
                mov     dl,2
                call    create_file

                pop     ax

                jc      fatal_working_error

                push    ax

                mov     al,2
                call    write_driver

                pop     ax

                jc      fatal_working_error

                push    ax

                mov     dl,2
                call    close_file

                pop     ax

                jc      fatal_working_error

; Process third file

                cmp     al,3
                jae     write_3_file

                clc
                jmp     write_working_return

        Write_3_file:

                mov     al,0
                mov     dl,3
                call    create_file

                jc      fatal_working_error

                mov     al,3
                call    write_driver

                jc      fatal_working_error

                mov     dl,3
                call    close_file

                jc      fatal_working_error

                clc

                jmp     write_working_return

        Fatal_working_error:

                stc

        Write_working_return:

                call    clear_monitor

                ret

Write_working   endp

Subttl          Load_fcb

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                       LOAD FILE CONTROL BLOCK                        |
; |                                                                      |
; ------------------------------------------------------------------------

Load_fcb        proc    near

                cmp     ah,1            ; determine if file is found
                jne     querry_first_file

; Find out what file is open and move it to fcb 1

                cmp     al,0
                je      file_already_to_go

                cmp     al,1
                jne     load_third_file

                mov     si,offset file_2_fcb
                jmp     set_up_first_fcb

        Load_third_file:

                mov     si,offset file_3_fcb

        Set_up_first_fcb:

                cld

                mov     di,offset file_1_fcb

                mov     cx,44

                rep     movsb

                jmp     file_already_to_go

; Process first file

        Querry_first_file:

                mov     dx,offset file_1_fcb
                call    search_next_entry

                jnc     open_first_file_for_load

                mov     ax,0
                clc
                jmp     load_fcb_return

        Open_first_file_for_load:

                mov     al,0
                mov     dl,1
                mov     si,0
                call    open_file

                jc      fatal_master_open_error

        File_already_to_go:

                mov     bx,file_1_dta
                mov     cl,4
                shl     bx,cl
                mov     current_memory_position,bx

                mov     al,1
                call    check_memory_size

                jnc     querry_second_file

                mov     ax,0100h
                stc
                jmp     load_fcb_return

; Process second file

        Querry_second_file:

                mov     dx,offset file_2_fcb
                call    search_next_entry

                jnc     open_second_file

                mov     ax,1
                clc
                jmp     load_fcb_return

        Open_second_file:

                mov     al,0
                mov     dl,2
                mov     si,0
                call    open_file

                jc      fatal_master_open_error

                mov     al,2
                call    check_memory_size

                jnc     querry_third_file

                mov     ax,0101h
                clc     
                jmp     load_fcb_return

; Process third file

        Querry_third_file:

                mov     dx,offset file_3_fcb
                call    search_next_entry

                jnc     open_third_file

                mov     ax,2
                clc
                jmp     load_fcb_return

        Open_third_file:

                mov     al,0
                mov     dl,3
                mov     si,0
                call    open_file

                jc      fatal_master_open_error

                mov     al,3
                call    check_memory_size

                jnc     all_fcb_loaded

                mov     ax,0102h
                clc     
                jmp     load_fcb_return

        All_fcb_loaded:

                mov     ax,0003h
                clc
                jmp     load_fcb_return

        Fatal_master_open_error:

                stc

        Load_fcb_return:

                ret

Load_fcb        endp

Subttl          Check_memory_size

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                         CHECK MEMORY SIZE                             |
; |                                                                       |
; |        Decide if the next file can fit into memory                    |
; |                                                                       |
; |        Input:                                                         |
; |                                                                       |
; |           AL - file control block to check                            |
; |                                                                       |
; -------------------------------------------------------------------------

Check_memory_size proc  near

                cmp     al,1
                jne     file_2_size

                mov     bx,offset file_1_fcb
                mov     dx,cs:[bx+16]
                jmp     process_file_size

        File_2_size:

                cmp     al,2
                jne     file_3_size

                mov     bx,offset file_2_fcb
                mov     dx,cs:[bx+16]
                jmp     process_file_size

        File_3_size:

                mov     bx,offset file_3_fcb
                mov     dx,cs:[bx+16]

        Process_file_size:

                mov     ax,0ffffh
                mov     cx,current_memory_position
                sub     ax,cx

                cmp     ax,dx             ; Is memory available > file size
                ja      memory_available

                stc
                jmp     check_memory_size_return

        Memory_available:

                add     cx,dx
                mov     current_memory_position,cx
                clc

        Check_memory_size_return:

                ret

Check_memory_size endp

Code_seg        ends

                end