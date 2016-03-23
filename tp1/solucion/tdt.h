#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

/** Tipos lista y nodo **/

typedef struct valor_t {
  uint8_t val[15];
} __attribute__((__packed__)) valor;

typedef struct clave_t {
  uint8_t cla[3];
} __attribute__((__packed__)) clave;

typedef struct valorValido_t {
  struct valor_t valor;
  uint8_t valido;
} __attribute__((__packed__)) valorValido;

typedef struct tdtN3_t {
  struct valorValido_t entradas[256];
} __attribute__((__packed__)) tdtN3;

typedef struct tdtN2_t {
  struct tdtN3_t* entradas[256];
} __attribute__((__packed__)) tdtN2;

typedef struct tdtN1_t {
  struct tdtN2_t* entradas[256];
} __attribute__((__packed__)) tdtN1;

typedef struct tdt_t {
  char* identificacion;
  struct tdtN1_t* primera;
  uint32_t cantidad;
} __attribute__((__packed__)) tdt;

typedef struct bloque_t {
  uint8_t clave[3];
  uint8_t valor[15];
} __attribute__((__packed__)) bloque;

typedef struct maxmin_t {
  uint8_t max_clave[3];
  uint8_t min_clave[3];
  uint8_t max_valor[15];
  uint8_t min_valor[15];
} __attribute__((__packed__)) maxmin;

// /** Funciones **/

tdt* tdt_crear(char* identificacion);
void tdt_recrear(tdt** tabla, char* identificacion);

uint32_t tdt_cantidad(tdt* tabla);

void tdt_agregar(tdt* tabla, uint8_t* clave, uint8_t* valor);
void tdt_agregarBloque(tdt* tabla, bloque* b);
void tdt_agregarBloques(tdt* tabla, bloque** b);

void tdt_borrar(tdt* tabla, uint8_t* clave);
void tdt_borrarBloque(tdt* tabla, bloque* b);
void tdt_borrarBloques(tdt* tabla, bloque** b);

void tdt_traducir(tdt* tabla, uint8_t* clave, uint8_t* valor);
void tdt_traducirBloque(tdt* tabla, bloque* b);
void tdt_traducirBloques(tdt* tabla, bloque** b);

void tdt_imprimirTraducciones(tdt* tabla, FILE* pFile);

maxmin* tdt_obtenerMaxMin(tdt* tabla);

void tdt_destruir(tdt** tabla);