/*
** 2021-05-08, Greg King
*/

#include <cbm.h>

/* Loads file "name", from device, to given VRAM address -- or, to the load
** address of the file if addr is 0xFFFFFF.  addr must be 17 bits wide.
** When addr is 0xFFFFFF, the current address bit 16 isn't changed.
** Returns the address after the end of the loaded file.
** Sets "_oserror" to a CBM result code (see <cbm.h>).
*/
unsigned long __fastcall__ vera_load (const char* name, unsigned char device,
                                      unsigned long addr);
{
    unsigned char bank = addr >> 16;

    VERA.control = 0b00000000;
    addr &= 0xFFFFFFuL;
    if (addr == 0xFFFFFFuL) {
        bank = VERA.address_hi;
    }

    /* LFN isn't needed for loading.  This call takes advantage of the fact
    ** that false is 0, and true is 1 in the C language.
    */
    cbm_k_setlfs(0, device, addr == 0xFFFFFFuL);
    cbm_k_setnam(name);

    /* We must ensure that address_hi is read _after_ cbm_k_load() is called.
    ** We put them in separate expressions.
    */
    __AX__ = cbm_k_load((bank & 0x0Fu) + 2u, addr);
    return __AX__ | ((unsigned long)(VERA.address_hi & (unsigned char)0x07u) << 16);
}
