
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../tp2.h"

#define DECLARE_LDR_EXT(ext) \
    void ldr_##ext (unsigned char *src, unsigned char *dst, int cols, int filas, \
                      int src_row_size, int dst_row_size, int alpha)

DECLARE_LDR_EXT(c);
DECLARE_LDR_EXT(asm);
DECLARE_LDR_EXT(sse);
DECLARE_LDR_EXT(sse_float);
DECLARE_LDR_EXT(avx);
DECLARE_LDR_EXT(avx2);

void ayuda_ldr();

typedef void (ldr_fn_t) (unsigned char*, unsigned char*, int, int, int, int, int);

int alpha;

void leer_params_ldr(configuracion_t *config, int argc, char *argv[]) {
    config->extra_config = &alpha;
    alpha = atoi(argv[argc - 1]);
}

void aplicar_ldr(configuracion_t *config)
{
    ldr_fn_t *ldr;

    if(strcmp(config->tipo_filtro,"c") == 0) {
        ldr = ldr_c;
    } else if(strcmp(config->tipo_filtro,"asm") == 0) {
        ldr = ldr_asm;
    } else if(strcmp(config->tipo_filtro,"sse") == 0) {
        ldr = ldr_sse;
    } else if(strcmp(config->tipo_filtro,"sse_float") == 0) {
        ldr = ldr_sse_float;
    } else if(strcmp(config->tipo_filtro,"avx") == 0) {
        ldr = ldr_avx;
    } else if(strcmp(config->tipo_filtro,"avx2") == 0) {
        ldr = ldr_avx2;
    } else {
        ayuda_ldr();
        return;
    }

    buffer_info_t info = config->src;
    ldr(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
                    config->dst.width_with_padding, alpha);

}

void ayuda_ldr()
{
    printf ( "       * ldr\n" );
    printf ( "           Parámetros       : \n"
             "                         alpha - valor entre -255 y 255. En caso\n"
             "                         de querer pasar un valor negativo anteponer --\n");
    printf ( "           Implementaciones : \n"
             "                         c, asm, sse, avx, avx2\n");
    printf ( "           Ejemplo de uso   : \n"
             "                         ldr -i c facil.bmp 120\n"
             "                         ldr -i c facil.bmp -- -200\n");
}


