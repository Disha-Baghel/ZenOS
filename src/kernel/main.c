#include "print.h"
#include "kernel/serial.h"
#include "kernel/io.h"
#include "interrupts/idt.h"
#include "multiboot2/multiboot2.h"
#include "kernel/vga.h"

void kernel_main(unsigned long addr) {

    print_clear();
    print_set_color(PRINT_COLOR_YELLOW, PRINT_COLOR_BLACK);

    enable_cursor(0, 0);
    
    kprintf("Welcome to ZenOS Kernel\n");

    init_serial();

    idt_init();
    sti();
}
