;
; 2009-07-27, Stefan Haubenthal
; 2014-07-11, Greg King
; 2018-08-14, Oliver Schmidt
;
; int __fastcall__ clock_gettime (clockid_t clk_id, struct timespec *tp);
;

        .include        "time.inc"
        .include        "c64.inc"

        .importzp       sreg, tmp1, tmp2
        .import         pushax, pusheax, tosmul0ax, steaxspidx, incsp1, return0
        .import         TM, load_tenth


;----------------------------------------------------------------------------
.code

.proc   _clock_gettime

        jsr     pushax
        jsr     pushax

; Get the hour, and freeze the output registers (the time components will stay
; co-ordinated).
        ldx     CIA1_TODHR
        lda     #0
        cpx     #$12                    ; Shift 12 AM to zero
        beq     is0

; Convert from 12-hour format to 24-hour format.
        txa
        bpl     AM
        and     #%01111111
        cmp     #$12                    ; Don't shift 12 PM
        beq     AM
; XXX -- Ollie's bad code?
        sed
        tax                     ; Save PM flag
        and     #%01111111
        cmp     #$12            ; 12 AM/PM
        bcc     @L1
        sbc     #$12
@L1:    inx                     ; Get PM flag
        bpl     @L2
        clc
        adc     #$12
@L2:    cld
; XXX -- End of Ollie's code.
AM:     jsr     BCD2dec
is0:    cmp     TM + tm::tm_hour
        bcs     today

; The new time is less than the old time; therefore, the clock must have gone
; past midnight.  Add 24 hours; mktime() will correct the hour and the date.

        ;clc
        adc     #24
today:  sta     TM + tm::tm_hour
        lda     CIA1_TODMIN
        jsr     BCD2dec
        sta     TM + tm::tm_min
        lda     CIA1_TODSEC
        jsr     BCD2dec
        sta     TM + tm::tm_sec
        lda     #<TM
        ldx     #>TM
        jsr     _mktime

        ldy     #timespec::tv_sec
        jsr     steaxspidx      ; Pops address pushed by 2. pushax

        jsr     load_tenth
        jsr     pusheax
        lda     CIA1_TOD10
        ldx     #>$0000
        jsr     tosmul0ax

        ldy     #timespec::tv_nsec
        jsr     steaxspidx      ; Pops address pushed by 1. pushax

        jsr     incsp1
        jmp     return0

.endproc

;----------------------------------------------------------------------------
; dec = (((BCD>>4)*10) + (BCD&0xf))

.proc   BCD2dec

        tax
        and     #%00001111
        sta     tmp1
        txa
        and     #%11110000      ; *16
        lsr                     ; *8
        sta     tmp2
        lsr
        lsr                     ; *2
        adc     tmp2            ; = *10
        adc     tmp1
        rts

.endproc
