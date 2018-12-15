.xlist

; *************************************************************************
; *                                                                       *
; *             (C)opyright 1983 Software Laboratories, Inc.              *
; *                                                                       *
; *                  Author Cameron L. Wolff                              *
; *                                                                       *
; *************************************************************************

;
; External data messages
;

    extrn  sli_dos_name:byte,ibm_bio_name:byte,ibm_dos_name:byte
    extrn  command_name:byte,strike_any_key_message:byte
    extrn  damaged_diskette_message:byte
    extrn  not_formatted_message:byte,write_protect_message:byte
    extrn  drive_not_ready_message:byte
    extrn  not_enough_space_message:byte,working_drive:byte
    extrn  working_copy_message_1:byte,working_copy_message_2:byte
    extrn  insert_master_message_1:byte,insert_master_message_2:byte
    extrn  not_write_protected_message:byte
    extrn  not_ibm_message:byte,format_message_1:byte,format_message_2:byte
    extrn  not_working_message:byte,not_master_message:byte
    extrn  please_write_protect_message_1:byte,insert_ibm_message_1:byte
    extrn  please_write_protect_message_2:byte,insert_ibm_message_2:byte
    extrn  no_room_for_system_message:byte
    extrn  reading_ibm_message_1:byte,writing_ibm_message_1:byte
    extrn  reading_ibm_message_2:byte,writing_ibm_message_2:byte
    extrn  reading_master_message_1:byte,fatal_work_message:byte
    extrn  reading_master_message_2:byte,writing_working_message_1:byte
    extrn  fatal_master_message:byte,writing_working_message_2:byte
    extrn  fatal_work_message:byte
    extrn  erase_key_files_message:byte,erase_files_message:byte
    extrn  add_key_files_message:byte,add_files_message:byte
    extrn  fatal_ibm_message:byte

;
; External data variables
;

    extrn  source_drive:byte,destination_drive:byte
    extrn  number_of_drives:byte,current_drive:byte
    extrn  attribute:byte,disk_retry:byte,format_block:byte
    extrn  current_track_side:word
    extrn  file_control_block:byte,any_file_name:byte,number_of_sides:byte
    extrn  general_dta_seg:word,search_fcb:byte,create_fcb:byte
    extrn  file_1_fcb:byte,file_2_fcb:byte,file_3_fcb:byte
    extrn  file_1_dta:word,file_2_dta:word,file_3_dta:word,end_of_3_dta:word
    extrn  disk_io_parameters:byte,current_memory_position:word
    extrn  picture_on_attribute:byte,picture_off_attribute:byte
    extrn  monitor_attribute:byte,error_attribute:byte
    extrn  current_disk:byte,current_error:byte,color:byte,current_drive:byte
    extrn  end_of_data:byte

.list
