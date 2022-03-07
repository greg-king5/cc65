;
; 2022-02-10, Greg King
;
	.fopt		compiler,"cc65 v 2.19 - Git c28839e31"
	.autoimport	on
	.debuginfo	off

	.importzp	sp, sreg, regsave, regbank
	.importzp	tmp1, tmp2, tmp3, tmp4, ptr1, ptr2, ptr3, ptr4
;	.import		__oserror
	.import		_write
	.import		seek_sector

        .include        "dio.inc"       ; export the function name
        .include        "diovals.inc"
        .include        "errno.inc"
;        .include        "filedes.inc"

.bss
;
; static dio_phys_pos pos;
;
_pos:
	.res	5

; ---------------------------------------------------------------
; unsigned char __near__ __fastcall__ dio_write (dhandle_t handle, unsigned sect_num, const void *buffer)
; ---------------------------------------------------------------

.code

.proc	_dio_write: near

;
; {
;
	jsr     pushax
;
; dhandle = (int)handle;
;
	ldy     #$05
	jsr     ldaxysp
	sta     dhandle
;
; if (dio_log_to_phys((dhandle_t)dhandle, &sect_num, &pos) != 0) {
;
	jsr     pushax
	lda     #$04
	jsr     leaa0sp
	jsr     pushax
	lda     #<(_pos)
	ldx     #>(_pos)
	jsr     _dio_log_to_phys
	cmp     #$00
;
; return _oserror;
;
	bne     L0006
;
; if (write(dhandle, buffer, 256u) < 256) {
;
	lda     dhandle
	jsr     pusha0
	ldy     #$05
	jsr     pushwysp
	ldx     #$01
	lda     #$00
	jsr     _write
	cmp     #$00
	txa
	sbc     #$01
	bvc     L0004
	eor     #$80
;
; return _oserror;
;
L0004:	bmi     L0006
;
; seek_sector(pos.track, pos.sector, '2');
;
	lda     _pos+dio_phys_pos::track
	ldx     _pos+dio_phys_pos::track+1
	jsr     pushax
	lda     _pos+dio_phys_pos::sector
	ldx     _pos+dio_phys_pos::sector+1
	
	jsr     pushax
	lda     #'2'
	jsr     seek_sector
;
; return _oserror;
;
L0006:	ldx     #$00
	lda     __oserror
;
; }
;
	jmp     incsp6

.endproc
