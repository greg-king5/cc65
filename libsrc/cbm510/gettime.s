;
; 2009-07-27, Stefan Haubenthal
; 2009-09-24, Ullrich von Bassewitz
; 2018-08-18, Oliver Schmidt
; 2018-08-19, Greg King
;
; int __fastcall__ clock_gettime (clockid_t clk_id, struct timespec *tp);
;

        .include        "time.inc"
        .include        "cbm510.inc"
        .include        "extzp.inc"

        .import         pushax, pusheax, tosmul0ax, steaxspidx, incsp1
        .import         sys_bank, restore_bank
        .import         TM, load_tenth
        .importzp       sreg, tmp1, tmp2


;----------------------------------------------------------------------------

.proc   _clock_gettime

        jsr     pushax
        jsr     pushax

; Get the hour, and freeze the output registers (the time components will stay
; co-ordinated).

        jsr     sys_bank
        ldy     #CIA::TODHR
        lda     (cia2),y
        tax
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
is0:    sta     TM + tm::tm_hour
        ldy     #CIA::TODMIN
        lda     (cia2),y
        jsr     BCD2dec
        sta     TM + tm::tm_min
        ldy     #CIA::TODSEC
        lda     (cia2),y
        jsr     BCD2dec
        sta     TM + tm::tm_sec
        ldy     #CIA::TOD10
        lda     (cia2),y
        jsr     restore_bank
        pha
        lda     #<TM
        ldx     #>TM
        jsr     _mktime

        ldy     #timespec::tv_sec
        jsr     steaxspidx      ; Pops address pushed by 2. pushax

        jsr     load_tenth
        jsr     pusheax
        pla
        ldx     #>$0000
        jsr     tosmul0ax

        ldy     #timespec::tv_nsec
        jsr     steaxspidx      ; Pops address pushed by 1. pushax

        lda     #$00
        tax
        jmp     incsp1

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
