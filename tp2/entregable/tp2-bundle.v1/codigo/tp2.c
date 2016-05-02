
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <limits.h>

#include "tp2.h"
#include "helper/tiempo.h"
#include "helper/libbmp.h"
#include "helper/utils.h"
#include "helper/imagenes.h"

// ~~~ seteo de los filtros ~~~

#define N_ENTRADAS_cropflip 1
#define N_ENTRADAS_sepia 1
#define N_ENTRADAS_ldr 1

DECLARAR_FILTRO(cropflip)
DECLARAR_FILTRO(sepia)
DECLARAR_FILTRO(ldr)

filtro_t filtros[] = {
    DEFINIR_FILTRO(cropflip) ,
    DEFINIR_FILTRO(sepia) ,
    DEFINIR_FILTRO(ldr) ,
    {0,0,0,0,0}
};

// ~~~ fin de seteo de filtros. Para agregar otro debe agregarse ~~~
//    ~~~ una linea en cada una de las tres partes anteriores ~~~
int comparLongLong(const void *a, const void *b){
   const unsigned long long *x = a, *y = b;
   if(*x > *y)
     return 1;
   else
     return(*x < *y) ? -1: 0;
 }

int comparLong(const void *a, const void *b){
   const unsigned long *x = a, *y = b;
   if(*x > *y)
     return 1;
   else
     return(*x < *y) ? -1: 0;
 }

int main( int argc, char** argv ) {

    configuracion_t config;
    config.dst.width = 0;

    procesar_opciones(argc, argv, &config);
    // Imprimo info
    if (!config.nombre)
    {
        printf ( "Procesando...\n");
        printf ( "  Filtro             : %s\n", config.nombre_filtro);
        printf ( "  Implementación     : %s\n", config.tipo_filtro );
        printf ( "  Archivo de entrada : %s\n", config.archivo_entrada);
    }

    filtro_t *filtro = detectar_filtro(&config);

    if (filtro != NULL) {
        filtro->leer_params(&config, argc, argv);
        correr_filtro_imagen(&config, filtro->aplicador);
    }

    return 0;
}

filtro_t* detectar_filtro(configuracion_t *config)
{
    for (int i = 0; filtros[i].nombre != 0; i++)
    {
        if (strcmp(config->nombre_filtro, filtros[i].nombre) == 0)
            return &filtros[i];
    }

    fprintf(stderr, "Filtro desconocido\n");
    return NULL; // avoid C warning
}


void imprimir_tiempos_ejecucion(
        unsigned long long int cycles, unsigned long long minCycles,
             unsigned long long maxCycles,
        struct timeval tvTotal, struct timeval tvMin, struct timeval tvMax,
        int cant_iteraciones) {

    printf("Tiempo de ejecución:\n");
    printf("  # iteraciones                     : %d\n", cant_iteraciones);
    printf("  # de ciclos insumidos totales     : %llu\n", cycles);
    printf("  # de ciclos insumidos por llamada : %.3f\n", (float)cycles/(float)cant_iteraciones);
    printf("  # minimo de ciclos insumidos      : %llu\n", minCycles);
    printf("  # maximo de ciclos insumidos      : %llu\n", maxCycles);
    printf("  tiempo total                      : %ld.%06ld\n", tvTotal.tv_sec, tvTotal.tv_usec);
    printf("  tiempo minimo                     : %ld.%06ld\n", tvMin.tv_sec, tvMin.tv_usec);
    printf("  tiempo maximo                     : %ld.%06ld\n", tvMax.tv_sec, tvMax.tv_usec);
}

void correr_filtro_imagen(configuracion_t *config, aplicador_fn_t aplicador)
{
    char *tipo_filtro_UPPER = (char*) malloc(strlen(config->tipo_filtro));
    strcpy(tipo_filtro_UPPER,config->tipo_filtro);
    for(char *p = tipo_filtro_UPPER; *p; p++) *p = toupper(*p);



    snprintf(config->archivo_salida, sizeof  (config->archivo_salida), "%s/%s.%s.%s%s.bmp",
             config->carpeta_salida, basename(config->archivo_entrada),
             config->nombre_filtro,  tipo_filtro_UPPER, config->extra_archivo_salida );

    if (config->nombre)
    {
        printf("%s\n", basename(config->archivo_salida));
    }
    else
    {

				unsigned long long * arrayLongLongs = malloc((config->cant_iteraciones)*sizeof(unsigned long long));
				unsigned long * arrayLongs = malloc((config->cant_iteraciones)*sizeof(unsigned long));
        imagenes_abrir(config);
        unsigned long long cyclesTotal = 0, cyclesStart, cyclesEnd,
                           cyclesMin = -1, cyclesMax = 0, cyclesPartial;
        struct timeval tvStart, tvEnd, tvMin, tvMax, tvPartial, tvTotal;

        timerclear(&tvTotal);
        timerclear(&tvMax);
        timerclear(&tvMin);
        tvMin.tv_sec = (__time_t) LONG_MAX;

        for (int i = 0; i < config->cant_iteraciones; i++){


            gettimeofday(&tvStart,NULL);
            MEDIR_TIEMPO_START(cyclesStart)
            aplicador(config);
            MEDIR_TIEMPO_STOP(cyclesEnd)
            gettimeofday(&tvEnd,NULL);

            timersub(&tvEnd, &tvStart, &tvPartial);

            timeradd(&tvTotal, &tvPartial, &tvTotal);
            if(timercmp(&tvPartial, &tvMin, <)) {
                tvMin = tvPartial;
            }
            if(timercmp(&tvPartial, &tvMax, >)) {
                tvMax = tvPartial;
            }

            cyclesPartial = cyclesEnd - cyclesStart;

            cyclesTotal += cyclesPartial;
            cyclesMin = cyclesPartial < cyclesMin ? cyclesPartial : cyclesMin;
            cyclesMax = cyclesPartial > cyclesMax ? cyclesPartial : cyclesMax;
						arrayLongLongs[i] = cyclesPartial;
						arrayLongs[i] =  tvPartial.tv_usec;
        }

				qsort(arrayLongs, config->cant_iteraciones, sizeof(unsigned long), comparLong);
				qsort(arrayLongLongs, config->cant_iteraciones, sizeof(unsigned long long), comparLongLong);
				unsigned long medianaLong = arrayLongs[config->cant_iteraciones / 2];
				unsigned long long medianaLongLong = arrayLongLongs[config->cant_iteraciones / 2];
        imagenes_guardar(config);
        imagenes_liberar(config);
        imprimir_tiempos_ejecucion(cyclesTotal, cyclesMin, cyclesMax,
                tvTotal, tvMin, tvMax,
                config->cant_iteraciones);
    }

    free(tipo_filtro_UPPER);
}
