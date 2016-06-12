/*
 * LCG ultra simple
 */

#include "random.h"

uint64_t next;

void srand(uint64_t seed){
    next = seed;
}

uint32_t rand(uint32_t max){
    next = next * 6364136223846793005 + 1;
    return (uint32_t) (next >> 32) % max;
}

