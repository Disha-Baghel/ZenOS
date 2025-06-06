#include "arch/x86_64/io.h"

inline uint8_t inb(uint16_t portnum) {
    uint8_t data;
    asm volatile("inb %w1, %0" : "=a"(data) : "Nd"(portnum));
    return data;
}

inline void outb(uint16_t portnum, uint8_t data) {
    asm volatile("outb %0, %w1" : : "a"(data), "Nd"(portnum));
}

inline uint16_t inw(uint16_t portnum) {
    uint16_t data;
    asm volatile("inw %w1, %0" : "=a"(data) : "Nd"(portnum));
    return data;
}

inline void outw(uint16_t portnum, uint16_t data) {
    asm volatile("outw %0, %w1" : : "a"(data), "Nd"(portnum));
}

inline void io_wait() {
    outb(0x80, 0x00);
}
