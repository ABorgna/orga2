
#include "../tp2.h"

#define MIN(x,y) ( x < y ? x : y )
#define MAX(x,y) ( x > y ? x : y )

#define P 2

void ldr_c (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size __attribute__((unused)),
    int dst_row_size __attribute__((unused)),
    int alpha)
{
    const int LDR_MAX = 5 * 5 * 255 * 3 * 255;

    bgra_t (*src_matrix)[cols] = (bgra_t(*)[cols]) src;
    bgra_t (*dst_matrix)[cols] = (bgra_t(*)[cols]) dst;

    for (int i = 0; i < filas; i++) {
        for (int j = 0; j < cols; j++) {
            bgra_t pixel = src_matrix[i][j * 4];

            // Copiamos directamente los bordes
            if(i >= 2 && i < filas-2 && j >= 2 && j < cols-2) {
                int acum = 0;

                for(char di = -2; di <= 2; di++) {
                    for(char dj = -2; dj <= 2; dj++) {
                        bgra_t neightbor = src_matrix[i+di][(j+dj)*4];

                        acum += neightbor.r;
                        acum += neightbor.g;
                        acum += neightbor.b;
                    }
                }

                pixel.r += (alpha * acum * pixel.r) / LDR_MAX;
                pixel.g += (alpha * acum * pixel.g) / LDR_MAX;
                pixel.b += (alpha * acum * pixel.b) / LDR_MAX;
            }

            dst_matrix[i][j * 4] = pixel;
        }
    }
}

