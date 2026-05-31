[BITS 16]

global _start
extern kernel_main

_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    call kernel_main

    cli
    hlt

global _putChar
_putChar:
    ; Dengan -mregparm=3, parameter pertama ada di register AX
    mov ah, 0x0E
    ; AL sudah berisi karakter (parameter pertama = AL/AX)
    int 0x10
    ret

global _setColor
_setColor:
    ; Parameter pertama (warna) ada di AL
    mov bl, al
    mov bh, 0
    mov ax, 0x0B00
    int 0x10
    ret

global _clearScreen
_clearScreen:
    mov ax, 0x0003
    int 0x10
    ret

global _getChar
_getChar:
    mov ah, 0x00
    int 0x16
    ret