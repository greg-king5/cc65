;
; unsigned char __fastcall__ dio_phys_to_log(dhandle_t handle,
;                                            dio_phys_pos *physpos,     /* input */
;                                            unsigned *sectnum);        /* output */
; /* convert physical sector address (head/track/sector) to logical sector number */
; /* return oserror (0 for success) */
;
; 2022-01-03, Greg King
;

        .import         popax, umul8x8r16
        .importzp       ptr1, ptr2, ptr3, ptr4
        .importzp       tmp1, tmp3

        .include        "dio.inc"       ; export the function name
        .include        "diovals.inc"
        .include        "errno.inc"
        .include        "filedes.inc"

        .macpack        generic


; Error entry: Set _oserror and errno using error code in .A.

bad_position:
        lda     #66             ; "bad track or sector number"
        .byte   $2C             ;(bit $xxxx)
invalid_fd:
        lda     #3              ; "file not open"
        jsr     __mappederrno   ; returns -1 in .XA
        inx
        lda     __oserror
        rts

_dio_phys_to_log:

; Save the input/output pointers.
; Use registers that won't be changed by umul8x8r16.

        sta     ptr4            ; pointer to result
        stx     ptr4+1

        jsr     popax
        sta     ptr2
        stx     ptr2+1          ; pointer to input structure

        jsr     popax
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
        sty     dhandle
        tya
        tax                     ; .X = dhandle

; Validate the input track and sector numbers.

        ldy     #dio_phys_pos::track+1
        lda     (ptr2),y
        bnz     bad_position    ; number too big
        lda     dioNumTracks,x
        dey
        cmp     (ptr2),y
        blt     bad_position    ; track too big
        lda     (ptr2),y
        bze     bad_position    ; track can't be zero
        sta     ptr1            ; (for umul8x8r16)
        dec     ptr1            ; count all sectors outside of wanted track

        ldy     #dio_phys_pos::sector+1
        lda     (ptr2),y
        bnz     bad_position    ; number too big
        sta     __oserror       ; clear _oserror
        lda     dioMaxSector,x
        bze     var_tracks      ; variable track lengths
        dey
        cmp     (ptr2),y
        blt     bad_position    ; sector too big

        jsr     umul8x8r16

final:  ldy     #dio_phys_pos::sector
        add     (ptr2),y        ; add sectors from wanted track
        bcc     @L1
        inx

; Store the result into the output variable.

@L1:    ldy     #$00
        sta     (ptr4),y
        iny
        txa
        sta     (ptr4),y
        ldx     #$00
        lda     __oserror
        rts

var_tracks:
        ldy     #$00            ; clear running total of sectors
        sty     tmp3
        sty     tmp3+1
        lda     dioForMap_l,x   ; (.X still has dhandle)
        sta     ptr3
        lda     dioForMap_h,x   ; get drive's sector map
        sta     ptr3+1
        lda     dioNumTracks,x
        lsr     a
        bcs     single          ; single-sided has odd number of tracks
        sta     tmp1
        lda     ptr1
        cmp     tmp1
        blt     single

; The wanted-track number is on side two.  Subtract the number of cylinders
; from that number to get an offset that's in the range of the sector arrays.

        ;sec                    ; (set by cmp above)
        sbc     tmp1
        sta     ptr1

        asl     tmp1            ; arrays have word elements, double offset
        ldy     tmp1
        lda     (ptr3),y        ; count all sectors on side one
        iny
        sta     tmp3
        lda     (ptr3),y
        sta     tmp3+1

single: asl     ptr1
        lda     tmp3
        ldy     ptr1
        add     (ptr3),y        ; add sectors from tracks outside of wanted track
        sta     tmp3
        lda     tmp3+1
        iny
        adc     (ptr3),y
        sta     tmp3+1
        jmp     final
