#ifndef __TP2__H__
#define __TP2__H__

#include <stdbool.h>
#include <stdint.h>
#include <sys/time.h>

#define FILTRO_C   0
#define FILTRO_ASM 1

typedef struct bgra_t {
    unsigned char b, g, r, a;
} __attribute__((packed)) bgra_t;

typedef struct bgra16_t {
    unsigned short b, g, r, a;
} __attribute__((packed)) bgra16_t;

typedef struct bgra32_t {
    unsigned int b, g, r, a;
} __attribute__((packed)) bgra32_t;



typedef struct bgr_t {
    unsigned char b, g, r;
} __attribute__((packed)) bgr_t;

typedef struct bgr16_t {
    unsigned short b, g, r;
} __attribute__((packed)) bgr16_t;

typedef struct bgr32_t {
    unsigned int b, g, r;
} __attribute__((packed)) bgr32_t;


typedef struct buffer_info_t
{
    int width, height, width_with_padding;
    unsigned char *bytes;
    unsigned int tipo;
} buffer_info_t;


typedef struct configuracion_t
{
    char *nombre_filtro;
    char *tipo_filtro;
    buffer_info_t src, src_2, dst;
    void *extra_config;

    char *archivo_entrada;
    char *archivo_entrada_2;
    char  archivo_salida[255];
    char *carpeta_salida;
    char *extra_archivo_salida;
    bool es_video;
    bool verbose;
    bool frames;
    bool nombre;
    int cant_iteraciones;
} configuracion_t;

typedef void (lector_params_fn_t) (configuracion_t *config, int, char *[]);
typedef void (aplicador_fn_t) (configuracion_t*);
typedef void (mostrador_ayuda_fn_t) (void);

typedef struct filtro_t {
    char *nombre;
    lector_params_fn_t   *leer_params;
    mostrador_ayuda_fn_t *ayuda;
    aplicador_fn_t       *aplicador;
    int                     n_entradas;
} filtro_t;

#define DECLARAR_FILTRO(nombre) lector_params_fn_t leer_params_##nombre; \
                                mostrador_ayuda_fn_t ayuda_##nombre; \
                                aplicador_fn_t aplicar_##nombre; \
                                int  n_entradas_##nombre;

#define DEFINIR_FILTRO(nombre) {#nombre, leer_params_##nombre, ayuda_##nombre, aplicar_##nombre, N_ENTRADAS_##nombre}

// ~~~ declaraciones de tp2 ~~~
extern filtro_t filtros[];
filtro_t* detectar_filtro(configuracion_t *config);
void      correr_filtro_imagen(configuracion_t *config, aplicador_fn_t aplicador);
void      imprimir_tiempos_ejecucion(
        unsigned long long int cycles, unsigned long long int minCycles,
            unsigned long long int maxCycles,
        struct timeval tvTotal, struct timeval tvMin, struct timeval tvMax,
        int cant_iteraciones);

// ~~~ declaraciones de cli.h ~~~
void      procesar_opciones(int argc, char **argv, configuracion_t *config);
void      imprimir_ayuda ( char *nombre_programa);

// ~~~ operaciones con timeval ~~~
# define timerisset(tvp)    ((tvp)->tv_sec || (tvp)->tv_usec)
# define timerclear(tvp)    ((tvp)->tv_sec = (tvp)->tv_usec = 0)
# define timercmp(a, b, CMP)                               \
  (((a)->tv_sec == (b)->tv_sec) ?                          \
   ((a)->tv_usec CMP (b)->tv_usec) :                       \
   ((a)->tv_sec CMP (b)->tv_sec))
# define timeradd(a, b, result)                            \
  do {                                                     \
    (result)->tv_sec = (a)->tv_sec + (b)->tv_sec;          \
    (result)->tv_usec = (a)->tv_usec + (b)->tv_usec;       \
    if ((result)->tv_usec >= 1000000)                      \
      {                                                    \
    ++(result)->tv_sec;                                    \
    (result)->tv_usec -= 1000000;                          \
      }                                                    \
  } while (0)
# define timersub(a, b, result)                            \
  do {                                                     \
    (result)->tv_sec = (a)->tv_sec - (b)->tv_sec;          \
    (result)->tv_usec = (a)->tv_usec - (b)->tv_usec;       \
    if ((result)->tv_usec < 0) {                           \
      --(result)->tv_sec;                                  \
      (result)->tv_usec += 1000000;                        \
    }                                                      \
  } while (0)

#endif   /* !__TP2__H__i*/
