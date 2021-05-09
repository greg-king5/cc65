/*
** 2021-03-16, Greg King
*/

#include <cbm.h>

//#define RAM_BANK VIA1.pra

/* Loads file "name", from given device, to given address -- or, to the load
** address of the file if addr is zero (like load"name",8,1 in BASIC).  addr
** must be three bytes.  The low two bytes are a RAM address.  The third byte
** is a RAM bank number when the RAM address is between 0xA000 and 0xBFFF;
** else, it is ignored.  When addr is zero, the current bank number is used.
** The current RAM bank number is preserved.
** Returns the address, including the bank number,
** that's one byte after the end of the loaded file.
** Sets "_oserror" to a CBM result code (see <cbm.h>).
**
** NOTE: Currently, only the emulator supports crossing the RAM bank boundary!
*/
unsigned long __fastcall__ cx_load (const char* name, unsigned char device,
                                    unsigned long addr)
{
    unsigned char bank = RAM_BANK;
    unsigned int data = (unsigned int)addr;

    if (addr != 0) {
        RAM_BANK = addr >> 16;
    }

    /* LFN isn't needed for loading.  This call takes advantage of the fact
    ** that false is 0, and true is 1 in the C language.
    */
    cbm_k_setlfs(0, device, data == 0);
    cbm_k_setnam(name);

    /* We must ensure that RAM_BANK is read _after_ cbm_k_load() is called.
    ** We put them in separate expressions.
    */
    __AX__ = cbm_k_load(0, data);
    addr = __AX__ | ((unsigned long)RAM_BANK << 16);

    RAM_BANK = bank;                    /* restore original bank number */
    return addr;
}
