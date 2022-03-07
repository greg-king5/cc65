;
; Interfaces for Low-level diskette I/O.
;
; 2015-08-15, Greg King
;

        .global _dio_query_sectsize, _dio_query_sectcount
        .global _dio_open, _dio_close
        .global _dio_read, _dio_write, _dio_write_verify
        .global _dio_phys_to_log, _dio_log_to_phys

; The ca65 structure must match the C structure in <dio.h>.
;
; typedef struct {
;   unsigned char head;
;   unsigned int  track;
;   unsigned int  sector;
; } dio_phys_pos;

        .struct dio_phys_pos
head    .byte
track   .word
sector  .word
        .endstruct
