
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../tp2.h"

#define DECLARE_SEPIA_EXT(ext) \
    void sepia_##ext (unsigned char *src, unsigned char *dst, int cols, int filas, \
                      int src_row_size, int dst_row_size, int alfa)

DECLARE_SEPIA_EXT(c);
DECLARE_SEPIA_EXT(c_o0);
DECLARE_SEPIA_EXT(c_o1);
DECLARE_SEPIA_EXT(c_o2);
DECLARE_SEPIA_EXT(asm);
DECLARE_SEPIA_EXT(avx2);

void ayuda_sepia();

typedef void (sepia_fn_t) (unsigned char*, unsigned char*, int, int, int, int, int);

int alfa;

void leer_params_sepia(configuracion_t *config, int argc, char *argv[]) {
    config->extra_config = &alfa;
    alfa = atoi(argv[argc - 1]);
}

void aplicar_sepia(configuracion_t *config)
{
    sepia_fn_t *sepia;
    if(strcmp(config->tipo_filtro,"c") == 0) {
        sepia = sepia_c;
    } else if(strcmp(config->tipo_filtro,"c_O3") == 0) {
        sepia = sepia_c;
    } else if(strcmp(config->tipo_filtro,"c_O2") == 0) {
        sepia = sepia_c_o2;
    } else if(strcmp(config->tipo_filtro,"c_O1") == 0) {
        sepia = sepia_c_o1;
    } else if(strcmp(config->tipo_filtro,"c_O0") == 0) {
        sepia = sepia_c_o0;
    } else if(strcmp(config->tipo_filtro,"asm") == 0) {
        sepia = sepia_asm;
    } else if(strcmp(config->tipo_filtro,"sse") == 0) {
        sepia = sepia_asm;
    } else if(strcmp(config->tipo_filtro,"avx2") == 0) {
        sepia = sepia_avx2;
    } else {
        ayuda_sepia();
        return;
    }

    buffer_info_t info = config->src;
    sepia(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
             config->dst.width_with_padding, alfa);

}

void ayuda_sepia()
{
    printf ( "       * sepia\n" );
    printf ( "           Parámetros       : \n"
             "                         ninguno\n");
    printf ( "           Implementaciones : \n"
             "                         c, c_O0, c_O1, c_O2, c_O3,"
             "                         asm, sse, avx2\n");
    printf ( "           Ejemplo de uso   : \n"
             "                         sepia -i c bgr.bmp\n");
}


