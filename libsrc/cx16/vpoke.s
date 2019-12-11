;
; 2019-12-22, Greg King
;
; #define vpoke(addr,data) _vpoke0 (data, addr)
; void fastcall _vpoke0 (unsigned char data, unsigned long addr);
; /* Put a byte into a location in VERA's internal address space.
; ** Use data port zero.
; */
;

        .export         __vpoke0

        .import         vaddr0, popa
        .include        "cx16.inc"


__vpoke0:
        jsr     vaddr0          ; put VERA's address
        jsr     popa
        sta     VERA::DATA0     ; write data to VERA port zero
        rts
