/*
 * LCG ultra simple
 */

#include "random.h"

uint64_t next;

void srand(uint64_t seed){
    next = seed;
}

uint32_t rand(uint32_t max){
    next = next * 1103515245 + 12345;
    return (uint32_t) (next & 0xFFFFFFFF) % max;
}

