
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../tp2.h"

#define DECLARE_CROPFLIP_EXT(ext) \
    void cropflip_##ext    (unsigned char *src, unsigned char *dst, int cols, int filas, \
                      int src_row_size, int dst_row_size, int tamx, int tamy, int offsetx, int offsety)

DECLARE_CROPFLIP_EXT(c);
DECLARE_CROPFLIP_EXT(c_o0);
DECLARE_CROPFLIP_EXT(asm);
DECLARE_CROPFLIP_EXT(sse);
DECLARE_CROPFLIP_EXT(asm_COPYN);
DECLARE_CROPFLIP_EXT(asm_COPYN_avx2);

void ayuda_cropflip();

typedef void (cropflip_fn_t) (unsigned char*, unsigned char*, int, int, int, int, int, int, int, int);

typedef struct cropflip_params_t {
    int tamx, tamy, offsetx, offsety;
} cropflip_params_t;


cropflip_params_t extra;
void leer_params_cropflip(configuracion_t *config, int argc, char *argv[]) {
    config->extra_config = &extra;
    extra.tamx    = atoi(argv[argc - 4]);
    extra.tamy    = atoi(argv[argc - 3]);
    extra.offsetx = atoi(argv[argc - 2]);
    extra.offsety = atoi(argv[argc - 1]);

    config->dst.width = extra.tamx;
    config->dst.height = extra.tamy;
}

void aplicar_cropflip(configuracion_t *config)
{
    cropflip_fn_t *cropflip;
    cropflip_params_t *extra = (cropflip_params_t*)config->extra_config;

    if(strcmp(config->tipo_filtro,"c") == 0) {
        cropflip = cropflip_c;
    } else if(strcmp(config->tipo_filtro,"c_o0") == 0) {
        cropflip = cropflip_c_o0;
    } else if(strcmp(config->tipo_filtro,"asm") == 0) {
        cropflip = cropflip_asm;
    } else if(strcmp(config->tipo_filtro,"sse") == 0) {
        cropflip = cropflip_sse;
    } else if(strcmp(config->tipo_filtro,"sse_par") == 0) {
        cropflip = cropflip_asm_COPYN;
    } else if(strcmp(config->tipo_filtro,"avx2") == 0) {
        cropflip = cropflip_asm_COPYN_avx2;
    } else {
        return;
    }

    buffer_info_t info = config->src;
    cropflip(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
             config->dst.width_with_padding, extra->tamx, extra->tamy, extra->offsetx, extra->offsety);

}

void ayuda_cropflip()
{
    printf ( "       * cropflip\n" );
    printf ( "           Parámetros       : \n"
             "                         tamx ancho del recuadro (debe ser multiplo de 16 y entrar en la imagen)\n"
             "                         tamy alto del recuadro\n"
             "                         offsetx pixels a partir de los cuales copiar del source\n"
             "                         offsety pixels a partir de los cuales copiar del source\n");
    printf ( "           Implementaciones : \n"
             "                         c, c_o0, asm, sse, sse_par, avx2\n");
    printf ( "           Ejemplo de uso   : \n"
             "                         cropflip -i c facil.bmp 32 32 40 50\n" );
}
