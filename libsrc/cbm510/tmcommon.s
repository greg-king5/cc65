;
; 2013-12-26, Greg King
; Oliver Schmidt, 16.8.2018
;
; Common stuff for the clock routines
;

        .export         TM, load_tenth

        .importzp       sreg


;----------------------------------------------------------------------------
.code

.proc   load_tenth

        lda     #<(100 * 1000 * 1000 / $10000)
        ldx     #>(100 * 1000 * 1000 / $10000)
        sta     sreg
        stx     sreg+1
        lda     #<(100 * 1000 * 1000)
        ldx     #>(100 * 1000 * 1000)
        rts

.endproc

;----------------------------------------------------------------------------
; tm struct with date set to 1970-01-01
.data

TM:     .word   0               ; tm_sec
        .word   0               ; tm_min
        .word   0               ; tm_hour
        .word   1               ; tm_mday
        .word   1 - 1           ; tm_mon
        .word   1970 - 1900     ; tm_year
        .word   0               ; tm_wday
        .word   0               ; tm_yday
        .word   .loword(-1)     ; tm_isdst
