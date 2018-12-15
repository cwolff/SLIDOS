Name            SLIDUTL

Title           Software_labs_inc_command

Subttl          Disk_utility

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
; External
;

                extrn   disk_failure:near
                extrn   verify_ibm:near
                extrn   verify_work:near

;
; Public
;

                public   read_driver
                public   write_driver
                public   search_first_entry
                public   search_next_entry
                public   open_file
                public   close_file
                public   create_file
                public   read_file
                public   write_file
                public   read_boot
                public   write_boot


Subttl          Read_driver

Page

; =========================================================================
; |                                                                       |
; |                           READ DRIVER                                 |
; |                                                                       |
; |    Read in the entire file into memory and set the next dta segmenr   |
; |                                                                       |
; |            Input:                                                     |
; |                   AL - file control block to read                     |
; |                                                                       |
; =========================================================================

Read_driver     proc    near

                push    ds

                cmp     al,1
                jne     read_fcb_2

                mov     dx,file_1_dta
                mov     di,offset file_2_dta
                jmp     read_operation

        Read_fcb_2:

                cmp     al,2
                jne     read_fcb_3

                mov     dx,file_2_dta
                mov     di,offset file_3_dta
                jmp     read_operation

        Read_fcb_3:

                mov     dx,file_3_dta
                mov     di,offset end_of_3_dta

        Read_operation:

                push    di

                mov     ds,dx

                xor     bx,bx 
                xor     cx,cx
                xor     dx,dx

        Read_loop:

                push    ax

                call    read_file

                inc     cx

                cmp     al,01
                je      file_is_read
                cmp     al,02
                je      segment_full_error

                mov     dx,ds              ; calulate next dta
                add     dx,20h
                mov     ds,dx
                xor     dx,dx

                cmp     al,03
                je      file_is_read

                pop     ax

                jmp     read_loop

        Segment_full_error:

                pop     ax
                pop     di

                stc
                jmp     read_driver_return

        File_is_read:

                pop     ax
                pop     di

                mov     cs:[di],ds         ; next dta segment

                clc

        Read_driver_return:

                pop     ds

                ret

Read_driver     endp

Subttl          Write_driver

Page

; =========================================================================
; |                                                                       |
; |                              WRITE DRIVER                             |
; |                                                                       |
; |                 Write an entire file to the diskette                  |
; |                                                                       |
; |          Input:                                                       |
; |                 AL - file control block to write                      |
; |                 BX - number of records to write low word              |
; |                 CX - number of records to write high word             |
; |        (record size is set to one and BX,CX is the file size          |
; |         as a result the number of records to be written equals        |
; |         the number of bytes [file size] in the file)                  |
; |                                                                       |
; =========================================================================

Write_driver    proc    near

                push    ds
                push    es

                push    cs
                push    cs
                pop     ds
                pop     es                

                cmp     al,1
                jne     write_fcb_2

                mov     dx,file_1_dta
                mov     di,file_2_dta
                jmp     write_operation

        Write_fcb_2:

                cmp     al,2
                jne     write_fcb_3

                mov     dx,file_2_dta
                mov     di,file_3_dta
                jmp     write_operation

        Write_fcb_3:

                mov     dx,file_3_dta
                mov     di,end_of_3_dta

        Write_operation:

                mov     ds,dx

                xor     dx,dx

        Write_file_operation:

                push    cx

                mov     cx,bx        ; assuming all files are < 64 K

                call    write_file

                pop     cx

                or      al,al
                jz      file_is_written

; Check to see if the file is larger than 64 k

                pop     cx

        File_is_multiple_of_64_k:

                cmp    cx,0
                je     file_is_written

        Disk_full_error:

                stc
                jmp     write_driver_return

        File_is_written:

                clc

        Write_driver_return:

                pop     es
                pop     ds

                ret

Write_driver    endp

Subttl          Search_first_entry

Page

; =========================================================================
; |                                                                       |
; |                          SEARCH FIRST ENTRY                           |
; |                                                                       |
; |           Used to find the first file on the Word Vision Master       |
; |                                                                       |
; |      Input:                                                           |
; |           AL - 0 convert to upper case AL - 1 leave as is             |
; |           SI - address of file to search for                          |
; |                                                                       |
; =========================================================================

Search_first_entry proc near

                push    ds
                push    es

                push    cs
                push    cs
                pop     ds
                pop     es

                push    ax
                push    si

                mov     dx,offset file_1_fcb
                mov     ah,1ah
                int     21h

                pop     si
                pop     ax

                mov     bx,offset search_fcb
                mov     dx,bx
                mov     cl,source_drive
                inc     cl
                mov     [bx],cl
                mov     di,bx
                inc     di
                mov     cx,11

                cmp     al,0
                je      search_upper_case_loop

                rep     movsb

                jmp     search_operation

        Search_upper_case_loop:

                mov     al,[si]
                cmp     al,20h
                je      search_ignore_blank

                xor     al,20h

        Search_ignore_blank:

                mov     [di],al

                inc     si
                inc     di

                loop    search_upper_case_loop

        Search_operation:

                mov     ah,11h
                int     21h

                clc
                or      al,al
                jz      search_first_entry_return

                stc

        Search_first_entry_return:

                pop     es
                pop     ds

                ret

Search_first_entry endp

Subttl          Search_next_entry

Page

; =========================================================================
; |                                                                       |
; |                          SEARCH NEXT ENTRY                            |
; |                                                                       |
; |      Used to find the rest of the files on the Word Vision Master     |
; |                                                                       |
; |      Input:                                                           |
; |             DX - dta segment for open file (fcb 1 to 3)               |
; |                                                                       |
; =========================================================================

Search_next_entry proc    near

                push    ds

                push    cs
                pop     ds

                mov     ah,1ah
                int     21h

                mov     bx,offset search_fcb
                mov     dx,bx
                mov     al,source_drive
                inc     al
                mov     [bx],al

                mov     ah,12h
                int     21h

                clc
                or      al,al
                jz      search_next_entry_return

                stc

        Search_next_entry_return:

                pop     ds

                ret

Search_next_entry endp

Subttl          Open_file

Page

; =========================================================================
; |                                                                       |
; |                            OPEN FILE                                  |
; |                                                                       |
; |          Entry:                                                       |  
; |                 AL - 0 normal fcb  AL - 1 hidden file (6)             |
; |                 DS:SI - address of name  (00,XXXXXXXXEEE)             |
; |                   if SI - 0 then name already loaded                  |
; |                 DL - file number (1-3)                                |
; |                                                                       |
; |          Exit:                                                        |
; |                 AL - 0 file opened                                    |
; |                 AL - ff no room in directory                          |
; |                                                                       |
; =========================================================================

Open_file       proc    near

                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    ds
                push    es

                push    cs
                push    cs
                pop     ds
                pop     es

; Check what FCB is to be used

                cmp     dl,1
                jne     open_2

                mov     di,offset file_1_fcb
                jmp     set_up_fcb_for_open

        Open_2:

                cmp     dl,2
                jne     open_3

                mov     di,offset file_2_fcb
                jmp     set_up_fcb_for_open

        Open_3:

                mov     di,offset file_3_fcb

        Set_up_fcb_for_open:

                push    di

; Check to see if normal or extended file control block

                cmp     al,0
                je      open_block

                mov     al,0ffh
                mov     [di],al
                add     di,6
                mov     al,6
                mov     [di],al
                inc     di

; Check to see if name already loaded

        Open_block:

                mov     al,source_drive
                inc     al
                mov     [di],al

                mov     ax,di
                add     ax,0eh             ; record size field

                push    ax

                inc     di

; Check to see if file name is already present

                cmp     si,0
                je      open_file_operation

                mov     cx,11

        Open_upper_case_loop:

                mov     al,[si]
                cmp     al,20h
                je      open_ignore_blank

                xor     al,20h

        Open_ignore_blank:

                mov     [di],al

                inc     si
                inc     di

                loop    open_upper_case_loop

; FCB set open the file

        Open_file_operation:

                pop     ax

                pop     dx                 ; dx FCB address

                push    ax

                mov     ah,0fh
                int     21h

                pop     bx                ; record size field

                or      al,al
                jz      set_record_size

; Fatal open error

                stc
                jmp     open_file_return

        Set_record_size:

                mov     ax,512
                mov     [bx],ax

                clc

        Open_file_return:

                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx

                ret

Open_file       endp

Subttl          Close_file

Page

; =========================================================================
; |                                                                       |
; |                            CLOSE FILE                                 |
; |                                                                       |
; |               Closes a selected File Clerk File                       |
; |                                                                       |
; |               Entry:                                                  |
; |                     DL - file number to close                         |
; |                                                                       |
; |               Exit:                                                   |
; |                     FCB for file number is zero filled                |
; |                     AL = 0 successful close                           |
; |                     AL = 1 diskette was changed                       |
; |                                                                       |
; =========================================================================

Close_file      proc     near

                push     bx
                push     cx
                push     dx
                push     si
                push     di
                push     ds
                push     es

                push     cs
                pop      ds

; Check what FCB is to be used

                cmp     dl,1
                jne     check_2_close

                mov     dx,offset file_1_fcb
                jmp     close_function

        Check_2_close:

                cmp     dl,2
                jne     check_3_close

                mov     dx,offset file_2_fcb
                jmp     close_function

        Check_3_close:

                mov     dx,offset file_3_fcb

        Close_function:

                mov      ah,10h
                int      21h

                or       al,al
                jnz      close_error

                clc
                jmp      close_file_return

        Close_error:

                stc

         Close_file_return:

                pop      es
                pop      ds
                pop      di
                pop      si
                pop      dx
                pop      cx
                pop      bx

                ret

Close_file      endp

Subttl          Create_file

Page

; =========================================================================
; |                                                                       |
; |                          CREATE FILE                                  |
; |                                                                       |
; |          Entry:                                                       |  
; |                 AL - 0 normal fcb  AL - 1 hidden file (6)             |
; |                 DL - file number (1-3)                                |
; |                                                                       |
; |          Exit:                                                        |
; |                 AL - 0 file opened                                    |
; |                 AL - ff no room in directory                          |
; |                 BX - file size low word                               |
; |                 CX - file size high word (size of file that was read) |
; |                                                                       |
; =========================================================================

Create_file     proc    near

                push    dx
                push    si
                push    di
                push    ds
                push    es

                push    cs
                push    cs
                pop     ds
                pop     es

; Check what FCB is to be used

                cmp     dl,1
                jne     create_2_open

                mov     dx,offset file_1_fcb
                jmp     set_up_fcb_for_create

        Create_2_open:

                cmp     dl,2
                jne     create_3_open

                mov     dx,offset file_2_fcb
                jmp     set_up_fcb_for_create

        Create_3_open:

                mov     dx,offset file_3_fcb

        Set_up_fcb_for_create:

                push    dx

                mov     di,dx

                mov     ah,destination_drive
                inc     ah

; Set drive correctly and get file size that was read from disk

                cmp     al,0
                jne     create_extended_fcb

                mov     [di],ah
                mov     bx,[di+16]
                mov     cx,[di+18]
                jmp     create_file_operation

        Create_extended_fcb:

                mov     [di+7],ah
                mov     bx,[di+7+16]
                mov     cx,[di+7+18]

        Create_file_operation:

                pop     dx

                push    bx
                push    cx

                push    dx

                mov     ah,16h
                int     21h

                pop     bx

                or      al,al
                jz      set_create_record_size

                stc
                jmp     create_file_return

; Set record size to 1 for file write operation and set random
; record number to zero

        Set_create_record_size:

                mov     ah,[bx]
                cmp     ah,0ffh
                jne     not_create_extended_fcb

                mov     ax,1
                mov     [bx+7+14],ax
                mov     ax,0
                mov     [bx+7+33],ax
                mov     [bx+7+35],ax
                jmp     successful_create

        Not_create_extended_fcb:

                mov     ax,1
                mov     [bx+14],ax
                mov     ax,0
                mov     [bx+33],ax
                mov     [bx+35],ax

        Successful_create:
                
                clc

        Create_file_return:

                pop     cx
                pop     bx

                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx

                ret

Create_file     endp

Subttl          Read_file

Page

; =========================================================================
; |                                                                       |
; |                            READ FILE                                  |
; |                                                                       |
; |               Performs a random read on selected file                 |
; |                                                                       |
; |               Entry:                                                  |
; |                     AL - file number to read                          |
; |                     BX,CX - record number                             |
; |                     DS:DX - DTA for file                              |
; |                                                                       |
; |               Exit:                                                   |
; |                     AL - 0 transfer was successful                    |
; |                     Al - 1 EOF                                        |
; |                     AL - 2 Not enough room in DTA                     |
; |                     AL - 3 partial record filled out with zero's      |
; |                                                                       |
; =========================================================================

Read_file       proc     near

                push     bx
                push     cx
                push     dx
                push     si
                push     di
                push     ds
                push     es

; Check what FCB is to be used

                cmp     al,1
                jne     check_2_read

                mov     di,offset file_1_fcb
                jmp     set_read_dta

        Check_2_read:

                cmp     al,2
                jne     check_3_read

                mov     di,offset file_2_fcb
                jmp     set_read_dta

        Check_3_read:

                mov     di,offset file_3_fcb

        Set_read_dta:

                mov      ah,1ah
                int      21h

; Set record number to read

                mov      ah,cs:[di]
                cmp      ah,0ffh
                jne      not_read_extended_fcb

                mov      cs:[di+33+7],cx
                mov      cs:[di+35+7],bx

                jmp      read_record

        Not_read_extended_fcb:

                mov      cs:[di+33],cx
                mov      cs:[di+35],bx

        Read_record:

                push     cs
                pop      ds

                mov      dx,di
                mov      ah,21h
                int      21h

        Read_return:

                pop      es
                pop      ds
                pop      di
                pop      si
                pop      dx
                pop      cx
                pop      bx

                ret

Read_file       endp

Subttl          Write_file

Page

; =========================================================================
; |                                                                       |
; |                           WRITE FILE                                  |
; |                                                                       |
; |               Performs a random block write of file                   |
; |                                                                       |
; |               Entry:                                                  |
; |                     AL - file control block to write                  |
; |                     CX number of record to write                      |
; |                     DS:DX - DTA to use                                |
; |                                                                       |
; |               Exit:                                                   |
; |                     AL - 0 transfer was successful                    |
; |                     Al - 1 Diskette full                              |
; |                     AL - 2 Not enough room in DTA                     |
; |                                                                       |
; =========================================================================

Write_file      proc     near

                push     bx
                push     cx
                push     dx
                push     si
                push     di
                push     ds
                push     es

; Check what FCB is to be used

                cmp     al,1
                jne     check_2_write

                mov     di,offset file_1_fcb
                jmp     set_write_dta

        Check_2_write:

                cmp     al,2
                jne     check_3_write

                mov     di,offset file_2_fcb
                jmp     set_write_dta

        Check_3_write:

                mov     di,offset file_3_fcb

        Set_write_dta:

                mov      ah,1ah
                int      21h

        Write_record:

                push     cs
                pop      ds

                mov      dx,di
                mov      ah,28h
                int      21h

        Write_return:

                pop      es
                pop      ds
                pop      di
                pop      si
                pop      dx
                pop      cx
                pop      bx

                ret

Write_file      endp

Subttl          Read_boot

Page

; =========================================================================
; |                                                                       |
; |                           READ BOOT                                   |
; |                                                                       |
; |                      Read Ibm Boot track                              |
; |                                                                       |
; =========================================================================

Read_boot       proc    near

                push    es

                mov     ax,general_dta_seg
                add     ax,20h
                mov     es,ax

                mov     disk_retry,3

        Read_boot_loop:

                mov     ax,0201h
                mov     cx,0001h
                mov     dh,0
                mov     dl,source_drive
                mov     bx,0
                int     13h

                jnc     read_boot_return

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     read_boot_loop

                call    disk_failure

                call    verify_ibm
                jc      fatal_read_boot_error

                mov     disk_retry,3
                jmp     read_boot_loop

        Fatal_read_boot_error:

                stc

        Read_boot_return:

                pop     es

                ret

Read_boot       endp

Subttl          Write_boot

Page

; =========================================================================
; |                                                                       |
; |                          WRITE BOOT                                   |
; |                                                                       |
; |                     Write Ibm Boot track                              |
; |                                                                       |
; =========================================================================

Write_boot      proc    near

                push    es

                mov     ax,general_dta_seg
                add     ax,20h
                mov     es,ax

; Set disk status word on boot track

                mov     bx,3
                cmp     number_of_sides,0
                je      single_sided_drive

                mov     ax,103h
                mov     es:[bx],ax
                jmp     write_boot_prepare

        Single_sided_drive:

                mov     ax,0008h
                mov     es:[bx],ax

        Write_boot_prepare:

                mov     disk_retry,3

        Write_boot_loop:

                mov     ax,0301h
                mov     cx,0001h
                mov     dh,0
                mov     dl,destination_drive
                mov     bx,0
                int     13h

                jnc     write_boot_return

                mov     current_error,ah

                xor     ax,ax
                int     13h

                dec     disk_retry
                jnz     write_boot_loop

                call    disk_failure

                call    verify_work

                jc      fatal_write_boot_error

                mov     disk_retry,3
                jmp     write_boot_loop

        Fatal_write_boot_error:

                stc

        Write_boot_return:

                pop     es

                ret

Write_boot      endp

Code_seg        ends

                end