
#include "../tp2.h"

#define MIN(x,y) ( x < y ? x : y )
#define MAX(x,y) ( x > y ? x : y )

#define P 2

void __attribute__((optimize("O3"))) ldr_c (
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
            bgra_t pixel = src_matrix[i][j];

            // Copiamos directamente los bordes
            if(i >= 2 && i < filas-2 && j >= 2 && j < cols-2) {
                int acum = 0;

                for(char di = -2; di <= 2; di++) {
                    for(char dj = -2; dj <= 2; dj++) {
                        bgra_t neightbor = src_matrix[i+di][(j+dj)];

                        acum += neightbor.r;
                        acum += neightbor.g;
                        acum += neightbor.b;
                    }
                }

                pixel.r = MIN(MAX(pixel.r + (alpha * acum * pixel.r) / LDR_MAX, 0), 255);
                pixel.g = MIN(MAX(pixel.g + (alpha * acum * pixel.g) / LDR_MAX, 0), 255);
                pixel.b = MIN(MAX(pixel.b + (alpha * acum * pixel.b) / LDR_MAX, 0), 255);
            }

            dst_matrix[i][j] = pixel;
        }
    }
}

void __attribute__((optimize("O0"))) ldr_c_o0 (
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
            bgra_t pixel = src_matrix[i][j];

            // Copiamos directamente los bordes
            if(i >= 2 && i < filas-2 && j >= 2 && j < cols-2) {
                int acum = 0;

                for(char di = -2; di <= 2; di++) {
                    for(char dj = -2; dj <= 2; dj++) {
                        bgra_t neightbor = src_matrix[i+di][(j+dj)];

                        acum += neightbor.r;
                        acum += neightbor.g;
                        acum += neightbor.b;
                    }
                }

                pixel.r = MIN(MAX(pixel.r + (alpha * acum * pixel.r) / LDR_MAX, 0), 255);
                pixel.g = MIN(MAX(pixel.g + (alpha * acum * pixel.g) / LDR_MAX, 0), 255);
                pixel.b = MIN(MAX(pixel.b + (alpha * acum * pixel.b) / LDR_MAX, 0), 255);
            }

            dst_matrix[i][j] = pixel;
        }
    }
}

void __attribute__((optimize("O1"))) ldr_c_o1 (
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
            bgra_t pixel = src_matrix[i][j];

            // Copiamos directamente los bordes
            if(i >= 2 && i < filas-2 && j >= 2 && j < cols-2) {
                int acum = 0;

                for(char di = -2; di <= 2; di++) {
                    for(char dj = -2; dj <= 2; dj++) {
                        bgra_t neightbor = src_matrix[i+di][(j+dj)];

                        acum += neightbor.r;
                        acum += neightbor.g;
                        acum += neightbor.b;
                    }
                }

                pixel.r = MIN(MAX(pixel.r + (alpha * acum * pixel.r) / LDR_MAX, 0), 255);
                pixel.g = MIN(MAX(pixel.g + (alpha * acum * pixel.g) / LDR_MAX, 0), 255);
                pixel.b = MIN(MAX(pixel.b + (alpha * acum * pixel.b) / LDR_MAX, 0), 255);
            }

            dst_matrix[i][j] = pixel;
        }
    }
}

void __attribute__((optimize("O2"))) ldr_c_o2 (
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
            bgra_t pixel = src_matrix[i][j];

            // Copiamos directamente los bordes
            if(i >= 2 && i < filas-2 && j >= 2 && j < cols-2) {
                int acum = 0;

                for(char di = -2; di <= 2; di++) {
                    for(char dj = -2; dj <= 2; dj++) {
                        bgra_t neightbor = src_matrix[i+di][(j+dj)];

                        acum += neightbor.r;
                        acum += neightbor.g;
                        acum += neightbor.b;
                    }
                }

                pixel.r = MIN(MAX(pixel.r + (alpha * acum * pixel.r) / LDR_MAX, 0), 255);
                pixel.g = MIN(MAX(pixel.g + (alpha * acum * pixel.g) / LDR_MAX, 0), 255);
                pixel.b = MIN(MAX(pixel.b + (alpha * acum * pixel.b) / LDR_MAX, 0), 255);
            }

            dst_matrix[i][j] = pixel;
        }
    }
}

