;
; unsigned __fastcall__ dio_query_sectcount (dhandle_t handle);
; /* Return the DIO sector count. */
;
; 2022-03-07, Greg King
;

        .import         ptr1:zp, umul8x8r16

        .include        "dio.inc"       ; export the function name
        .include        "diovals.inc"
        .include        "errno.inc"
        .include        "filedes.inc"

        .macpack        generic


; Error entry: Set _oserror and errno using error code in .A; and, return zero.

invalid_fd:
        lda     #3              ; "file not open"
        jsr     __mappederrno   ; returns -1 in .XA
        inx
        txa
        rts

_dio_query_sectcount:
        cpx     #>$0000
        bne     invalid_fd      ; handle too big
        tay
        bze     invalid_fd      ; handle == NULL
        cpy     #MAX_FDS + 1
        bge     invalid_fd
        stx     __oserror       ; _oserror = 0;

; Check if the file is open.

        lda     fdtab - 1,y     ; get flags for that handle
        and     #LFN_OPEN
        bze     invalid_fd

; If the size already is known, then return it.  Else, compute it.

        ldx     dioSectCount_h - 1,y
        bze     @L1             ; count == 0; it's unknown
        lda     dioSectCount_l - 1,y
        rts

@L1:    lda     dioMaxSector - 1,y
        cmp     #$0100 - 1
        beq     noMult
        ;clc                    ; (comparison cleared carry)
        adc     #1              ; sector numbers start at zero
        sta     ptr1
        lda     dioNumTracks - 1,y
        sty     dhandle
        jsr     umul8x8r16
        ldy     dhandle
        bnz     save            ;(bra)

; Multiplying by $0100 shifts the low byte to the high byte.

noMult: ldx     dioNumTracks - 1,y
        lda     #<$0000

; Save the count for the next time.

save:   pha
        txa
        sta     dioSectCount_h - 1,y
        pla
        sta     dioSectCount_l - 1,y
        rts
