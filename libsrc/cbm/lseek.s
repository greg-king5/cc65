;
; 2014-07-15, Greg King
;
; #include <unistd.h>
; typedef long off_t;
; off_t __fastcall__ lseek(int fd, off_t offset, int whence);
;

        .export         _lseek

        .import         incsp6, popeax, popax
        .import         isdisk, writefndiskcmd, readdiskerror
        .import         fnunit, fnlen, fnbuf

        .include        "zeropage.inc"
        .include        "errno.inc"
        .include        "filedes.inc"
        .include        "stdio.inc"
        .macpack        generic

badfd:  lda     #EBADF
        bnz     err             ; branch always

; Only SEEK_SET is supported; return -1 and the ENOSYS errno value.
;
no_supp:
        jsr     incsp6          ; throw away fd and offset
        lda     #ENOSYS
err:    jsr     __directerrno   ; returns with -1 in .XA
        sta     sreg
        stx     sreg+1
        rts

; Function entry point

_lseek: cmp     #SEEK_SET
        bne     no_supp
;       sta     tmp1            ; save whence mode
        txa
        bnz     no_supp         ; jump if whence > 255

        jsr     popeax
        sta     fnbuf+1         ; put offset into position command
        stx     fnbuf+2
        lda     sreg
        ldx     sreg+1
        sta     fnbuf+3
        stx     fnbuf+4

; Check if we have a valid handle.

        jsr     popax           ; get fd
        cpx     #>0
        bne     badfd
        cmp     #MAX_FDS        ; is it valid?
        bge     badfd           ; jump if no
        tay
        ;clc                    ; (the cmp above cleared the carry)
        adc     #LFN_OFFS
        sta     fnbuf           ; put channel number into command

; Check if the file is actually open.

        lda     fdtab,y         ; get flags for this handle
        and     #LFN_OPEN
        bze     badfd

; Check for a disk device.

        ldx     unittab,y       ; get unit number
        jsr     isdisk
        bcs     badunit
        stx     fnunit
        sty     tmp4            ; save fd

; Send the command.

        ldy     #1 + 4          ; channel # and long position
        sty     fnlen
        lda     #'p'            ; the Position command
        jsr     writefndiskcmd
        bnz     oserr

; Get the status.

        ldx     fnunit
        jsr     readdiskerror
        bnz     oserr

; No errors; clear the end-of-file flag, and return the new position.

        ldy     tmp4            ; get back fd
        lda     fdtab,y
        and     #<~LFN_EOF
        sta     fdtab,y

        ldx     fnbuf+4         ; get offset
        lda     fnbuf+3
        stx     sreg+1
        sta     sreg
        ldx     fnbuf+2
        lda     fnbuf+1
        rts

badunit:
        lda     #9              ; "illegal device"
oserr:  jsr     __mappederrno   ; returns with -1 in .XA
        sta     sreg
        stx     sreg+1
        rts
