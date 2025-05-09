global loader

extern kmain

bits 64
long_mode_start:
    mov ax, gdt64.Data
    mov ds, rax
    mov es, rax
    mov fs, rax
    mov gs, rax
    mov ss, ax

    call kmain

.halt:
    hlt
    jmp .halt

global lgdt
lgdt:
    lgdt [gdt64.Pointer]
    ret

global ltr
ltr:
    mov di, gdt64.Tss
    ltr di
    ret

global lidt
lidt:
    lidt [rdi]
    ret

global cli
cli:
    cli
    ret

global sti
sti:
    sti
    ret

global invlpg
invlpg:
    invlpg [rdi]
    ret

global get_current_pml4
get_current_pml4:
    mov rax, cr3
    ret

global get_faulting_address
get_faulting_address:
    mov rax, cr2
    ret

section .text
bits 32
loader:
    mov esp, kernel_stack + KERNEL_STACK_SIZE

    mov [multiboot_addr], ebx

    call setup_page_tables

    lgdt [gdt64.Pointer]
    jmp gdt64.Code:long_mode_start

    hlt

setup_page_tables:
    mov eax, pdpt
    or eax, 0b11 ; present, writable
    mov [pml4], eax

    mov eax, pd
    or eax, 0b11 ; present, writable
    mov [pdpt], eax

    mov ecx, 0 ; counter

.loop:
    mov eax, 0x200000
    mul ecx
    or eax, 0b10000011 ; present, writable, huge page
    mov [pd + ecx * 8], eax

    inc ecx
    cmp ecx, 512
    jne .loop

.enable_paging:
    ; pass page table location to cpu
    mov eax, pml4
    mov cr3, eax

    ; enable Physical Address Extension (PAE)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; enable long mode
    mov ecx, 0xC0000080
    rdmsr ; read model-specific register
    or eax, 1 << 8
    wrmsr ; write model-specific register

    ; enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

section .data
global multiboot_addr
multiboot_addr: dd 0

section .bss
align 4096
global pml4
pml4:
    resb 4096
pdpt:
    resb 4096
pd:
    resb 4096

section .bss
global tss_segment
tss_segment:
    resd 1 ; reserved 
    resq 3 ; resp
    resq 2 ; reserved
    resq 7 ; ist
    resq 2 ; reserved
    resw 1 ; I/O map base address

PRESENT        equ 1 << 7
NOT_SYS        equ 1 << 4
EXEC           equ 1 << 3
DC             equ 1 << 2
RW             equ 1 << 1
ACCESSED       equ 1 << 0

; Flags bits
GRAN_4K       equ 1 << 7
SZ_32         equ 1 << 6
LONG_MODE     equ 1 << 5

section .rodata
align 8
global gdt64
gdt64:
    .Null: equ $ - gdt64
        dq 0
    .Code: equ $ - gdt64
        dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
        db 0                                        ; Base (mid, bits 16-23)
        db PRESENT | NOT_SYS | EXEC | RW            ; Access
        db GRAN_4K | LONG_MODE | 0xF                ; Flags & Limit (high, bits 16-19)
        db 0                                        ; Base (high, bits 24-31)
    .Data: equ $ - gdt64
        dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
        db 0                                        ; Base (mid, bits 16-23)
        db PRESENT | NOT_SYS | RW                   ; Access
        db GRAN_4K | SZ_32 | 0xF                    ; Flags & Limit (high, bits 16-19)
        db 0                                        ; Base (high, bits 24-31)
    .Tss: equ $ - gdt64
        dq 0
        dq 0
    .Pointer:
        dw $ - gdt64 - 1
        dq gdt64

KERNEL_STACK_SIZE equ 4096

align 16
section .bss
kernel_stack:
    resb KERNEL_STACK_SIZE
