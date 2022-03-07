;
; 2002-11-16, Ullrich von Bassewitz
; 2018-02-26, Greg King
;

        .import         SETNAM, SETLFS, OPEN, CLOSE
        .import         opencmdchannel, closecmdchannel
        .import         readdiskerror, writediskcmd
        .import         dio_get_format
        .import         _close
        .importzp       tmp2, tmp3

        .include        "dio.inc"       ; export the function names
        .include        "errno.inc"
        .include        "cbm.inc"
        .include        "filedes.inc"
        .include        "diovals.inc"

        .macpack        generic


;--------------------------------------------------------------------------
.rodata

bufname:.byte   "#"


.code
;--------------------------------------------------------------------------
;
; dhandle_t __fastcall__ dio_open (unsigned char device);
; /* Open device for subsequent DIO access. */
;
; This CBM version will fail if there is no disk,
; or if the disk is not formatted.

.proc   _dio_open

; Must be 8 <= device < 31.

        cmp     #FIRST_DRIVE
        blt     baddev
        cmp     #FIRST_DRIVE + MAX_DRIVES
        bge     baddev
        sta     tmp3            ; save unit #

; Get a free file handle; and, save it in tmp2 and dhandle.

        jsr     freefd
        lda     #1              ; "too many files"
        bcs     oserror         ; jump in case of error
        stx     tmp2
        lda     tmp3
        sta     unittab,x       ; save device #, for command functions
        stx     dhandle

        txa
        add     #LFN_OFFS       ; file #
        ldx     tmp3            ; unit #
        tay                     ; use file # as SA also
        jsr     SETLFS          ; set file params.

        lda     #.sizeof(bufname)
        ldx     #<bufname
        ldy     #>bufname
        jsr     SETNAM          ; set the file name

        jsr     OPEN
        bcs     oserror

; Open the drive unit's command channel; and, read it.

        ldx     tmp3            ; unit #
        jsr     opencmdchannel
        bnz     closeandexit
        ldx     tmp3
        jsr     readdiskerror
        bnz     closeandexit    ; branch on error

; Learn the disk's format.  Quit if it cannot be discoverred.

        jsr     dio_get_format
        bnz     closeandexit

; File is open.  Mark it in a table.

        ldx     tmp2
        lda     #LFN_OPEN
        sta     fdtab,x

; Return the handle in .XA.
; Note:  dhandle_t is declared as a pointer.  But, it's opaque; it can be
; anything, as long as it isn't zero.  The CBM version is a POSIX file
; descriptor.

        inx                     ; make sure not zero
        txa
        ldx     #>$0000
        rts

baddev: lda     #9              ; "illegal device"
        bnz     oserror         ; branch always

; Error entry: Close the file; and, exit.  OS error code is in .A, on entry.

closeandexit:
        pha
        lda     tmp2
        add     #LFN_OFFS
        jsr     CLOSE
        ldx     tmp3
        jsr     closecmdchannel
        pla

; Error entry: Set _oserror and errno using error code in .A; and, return NULL.

oserror:jsr     __mappederrno   ; returns -1 in .XA
        inx
        txa
        rts
.endproc

;--------------------------------------------------------------------------
;
; unsigned char __fastcall__ dio_close (dhandle_t handle);
; /* Close device; return oserror (0 for success). */

.proc   _dio_close
        sub     #1

; dio_open() is a special case of open(); therefore, just use close().

        jsr     _close
        lda     __oserror
        ldx     #>$0000
        rts
.endproc
