
#include "../tp2.h"


void __attribute__((optimize("O3"))) sepia_c    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size)
{
    //unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    //unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    bgra_t (*src_matrix)[cols] = (bgra_t(*)[cols]) src;
    bgra_t (*dst_matrix)[cols] = (bgra_t(*)[cols]) dst;

    for (int i = 0; i < filas; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            bgra_t pixel = src_matrix[i][j];
            unsigned short suma = pixel.r + pixel.g + pixel.b;
            unsigned short suma_r = 0.5*suma;
            if(suma_r < 255)                                    //Este número puede dar más de 255. Por eso le calculo el mínimo
                pixel.r = suma_r;
            else
                pixel.r = 255;
            pixel.g = 0.3*suma;                                 //Este no
            pixel.b = 0.2*suma;                                 //Este menos

            dst_matrix[i][j] = pixel;
        }
    }   //COMPLETAR
}

void __attribute__((optimize("O0"))) sepia_c_o0    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size)
{
    //unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    //unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    bgra_t (*src_matrix)[cols] = (bgra_t(*)[cols]) src;
    bgra_t (*dst_matrix)[cols] = (bgra_t(*)[cols]) dst;

    for (int i = 0; i < filas; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            bgra_t pixel = src_matrix[i][j];
            unsigned short suma = pixel.r + pixel.g + pixel.b;
            unsigned short suma_r = 0.5*suma;
            if(suma_r < 255)                                    //Este número puede dar más de 255. Por eso le calculo el mínimo
                pixel.r = suma_r;
            else
                pixel.r = 255;
            pixel.g = 0.3*suma;                                 //Este no
            pixel.b = 0.2*suma;                                 //Este menos

            dst_matrix[i][j] = pixel;
        }
    }   //COMPLETAR
}

void __attribute__((optimize("O1"))) sepia_c_o1    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size)
{
    //unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    //unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    bgra_t (*src_matrix)[cols] = (bgra_t(*)[cols]) src;
    bgra_t (*dst_matrix)[cols] = (bgra_t(*)[cols]) dst;

    for (int i = 0; i < filas; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            bgra_t pixel = src_matrix[i][j];
            unsigned short suma = pixel.r + pixel.g + pixel.b;
            unsigned short suma_r = 0.5*suma;
            if(suma_r < 255)                                    //Este número puede dar más de 255. Por eso le calculo el mínimo
                pixel.r = suma_r;
            else
                pixel.r = 255;
            pixel.g = 0.3*suma;                                 //Este no
            pixel.b = 0.2*suma;                                 //Este menos

            dst_matrix[i][j] = pixel;
        }
    }   //COMPLETAR
}

void __attribute__((optimize("O2"))) sepia_c_o2    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size)
{
    //unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    //unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    bgra_t (*src_matrix)[cols] = (bgra_t(*)[cols]) src;
    bgra_t (*dst_matrix)[cols] = (bgra_t(*)[cols]) dst;

    for (int i = 0; i < filas; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            bgra_t pixel = src_matrix[i][j];
            unsigned short suma = pixel.r + pixel.g + pixel.b;
            unsigned short suma_r = 0.5*suma;
            if(suma_r < 255)                                    //Este número puede dar más de 255. Por eso le calculo el mínimo
                pixel.r = suma_r;
            else
                pixel.r = 255;
            pixel.g = 0.3*suma;                                 //Este no
            pixel.b = 0.2*suma;                                 //Este menos

            dst_matrix[i][j] = pixel;
        }
    }   //COMPLETAR
}

