#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "tdt.h"

char *archivoCasoChico  =  "salida.caso.chico.txt";
char *archivoCasoGrande =  "salida.caso.grande.txt";
void casoC();
void casoG();

uint8_t clave1[3] = {1,2,3};
uint8_t valor1[15] = {3,4,5,6,7,8,4,5,63,2,3,4,5,6,5};
uint8_t clave2[3] = {2,2,2};
uint8_t valor2[15] = {3,4,5,3,7,8,4,5,63,2,3,4,5,6,5};
uint8_t clave3[3] = {3,2,3};
uint8_t valor3[15] = {3,4,5,6,7,8,4,5,0,2,3,4,5,6,5};
uint8_t clave4[3] = {8,9,3};
uint8_t valor4[15] = {3,4,5,6,7,8,4,5,63,2,3,4,5,6,5};
uint8_t clave5[3] = {0,2,2};
uint8_t valor5[15] = {63,4,5,2,7,8,4,5,0,2,3,4,5,6,5};
uint8_t clave6[3] = {7,2,3};
uint8_t valor6[15] = {3,4,5,6,7,8,4,5,63,2,3,4,5,6,5};
uint8_t clave7[3] = {8,2,3};
uint8_t valor7[15] = {9,4,5,6,7,8,4,5,63,2,3,4,5,6,5};

uint8_t claveMin[3] = {0,0,0};
uint8_t claveMax[3] = {255,255,255};
uint8_t valorMax[15] = {255,255,255,255,255,255,255,255,255,255,255,255,255,255,255};
uint8_t valorMin[15] = {  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0};

bloque b1 = {{1,5,3},{3,4,5,6,7,8,4,5,6,2,3,4,5,0,5}};
bloque b2 = {{2,5,2},{3,4,5,3,7,8,4,3,0,2,0,4,5,6,5}};
bloque b3 = {{3,5,3},{3,4,5,6,7,8,4,5,0,2,3,4,5,6,5}};

bloque* b[4] = {&b1,&b2,&b3,0};

int main() {
  srand(70);
  remove(archivoCasoChico);
  casoC();
  remove(archivoCasoGrande);
  casoG();
  return 0;
}

void printmaxmin(FILE *pFile, tdt* tabla) {
    int i;
    maxmin *mm = tdt_obtenerMaxMin(tabla);
    fprintf(pFile,"max_clave = %i",mm->max_clave[0]);
    for(i=1;i<3;i++) fprintf(pFile,"-%i",mm->max_clave[i]);
    fprintf(pFile,"\n");
    fprintf(pFile,"min_clave = %i",mm->min_clave[0]);
    for(i=1;i<3;i++) fprintf(pFile,"-%i",mm->min_clave[i]);
    fprintf(pFile,"\n");
    fprintf(pFile,"max_valor = %i",mm->max_valor[0]);
    for(i=1;i<15;i++) fprintf(pFile,"-%i",mm->max_valor[i]);
    fprintf(pFile,"\n");
    fprintf(pFile,"min_valor = %i",mm->min_valor[0]);
    for(i=1;i<15;i++) fprintf(pFile,"-%i",mm->min_valor[i]);
    fprintf(pFile,"\n");
    free(mm);
}

void printBloque(FILE *pFile, bloque* b) {
    int i;
    fprintf(pFile,"%i",b->clave[0]);
    for(i=1;i<3;i++) fprintf(pFile,"-%i",b->clave[i]);
    fprintf(pFile," => ");
    fprintf(pFile,"%i",b->valor[0]);
    for(i=1;i<15;i++) fprintf(pFile,"-%i",b->valor[i]);
    fprintf(pFile,"\n");  
}

void casoC(){
    FILE *pFile;
    tdt *tabla = tdt_crear("sa");
    
    pFile = fopen( archivoCasoChico, "a" );
    
    fputs( ">>> Test : operaciones sobre tabla vacia\n", pFile );
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    printmaxmin(pFile, tabla);
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_borrar(tabla,clave1);
    tdt_borrar(tabla,clave2);
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    tdt_borrar(tabla,clave3);
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_borrarBloque(tabla,&b1);
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    tdt_borrarBloque(tabla,&b2);
    tdt_borrarBloque(tabla,&b3);
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_borrarBloques(tabla,(bloque**)&b);
    tdt_imprimirTraducciones(tabla, pFile);
    fprintf(pFile,"\n");

    fputs( ">>> Test : operaciones basicas sobre tabla no vacia\n", pFile );
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_agregar(tabla, clave1, valor1);
    tdt_agregar(tabla, clave2, valor2);
    tdt_agregar(tabla, clave3, valor3);
    tdt_agregar(tabla, clave4, valor4);
    tdt_agregar(tabla, clave5, valor5);
    tdt_agregar(tabla, clave6, valor6);
    tdt_agregar(tabla, clave7, valor7);   
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_borrar(tabla,clave2);
    tdt_borrar(tabla,clave3);
    tdt_borrar(tabla,clave4);
    tdt_borrar(tabla,clave5);
    tdt_imprimirTraducciones(tabla, pFile);
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    fprintf(pFile,"\n");
    
    fputs( ">>> Test : operaciones sobre tabla no vacia\n", pFile );
    
    tdt_imprimirTraducciones(tabla, pFile);
    printmaxmin(pFile, tabla);
    tdt_agregar(tabla, clave1, valor1);
    printmaxmin(pFile, tabla);
    tdt_agregar(tabla, clave2, valor2);
    printmaxmin(pFile, tabla);
    tdt_agregar(tabla, clave3, valor3);
    printmaxmin(pFile, tabla);
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_agregar(tabla, clave4, valor4);
    printmaxmin(pFile, tabla);
    tdt_agregar(tabla, clave5, valor5);
    printmaxmin(pFile, tabla);
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    tdt_agregar(tabla, clave6, valor6);
    printmaxmin(pFile, tabla);
    tdt_agregar(tabla, clave7, valor7);   
    printmaxmin(pFile, tabla);
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_agregarBloque(tabla,&b1);
    tdt_agregarBloque(tabla,&b1);
    tdt_agregarBloque(tabla,&b1);
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_agregarBloques(tabla,(bloque**)&b);
    tdt_agregarBloques(tabla,(bloque**)&b);
    tdt_agregarBloques(tabla,(bloque**)&b);
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_borrar(tabla,clave1);
    tdt_borrar(tabla,clave2);
    tdt_borrar(tabla,clave2);
    tdt_borrar(tabla,clave3);
    tdt_borrar(tabla,clave7);
    tdt_borrarBloques(tabla,(bloque**)&b);
    tdt_imprimirTraducciones(tabla, pFile);
    fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
    tdt_recrear(&tabla,"saaaaaaaaaaaaaaaaaa");
    tdt_agregarBloques(tabla,(bloque**)&b);
    tdt_imprimirTraducciones(tabla, pFile);
    tdt_destruir(&tabla);
    
    fclose( pFile );
}

void casoG() {
      FILE *pFile;
      pFile = fopen( archivoCasoGrande, "a" );
      
      /* creo un vector de bloques con datos al azar */
      uint32_t i,j,n = 10000;
      bloque* arrayBloques = (bloque*)malloc(sizeof(bloque)*(n));
      bloque** bb = (bloque**)malloc(sizeof(bloque*)*(n+1));
      bloque* arrayBloquesTraducir = (bloque*)malloc(sizeof(bloque)*(n));
      bloque** bbTraducir = (bloque**)malloc(sizeof(bloque*)*(n+1));
      uint32_t *fastFill = (uint32_t*)(arrayBloques);
      for(i=0;i<n*sizeof(bloque)/sizeof(uint32_t);i++)
        fastFill[i] = rand();
      for(i=0;i<n;i++) {
        bb[i] = &(arrayBloques[i]);
        bbTraducir[i] = &(arrayBloquesTraducir[i]);
        bbTraducir[i]->clave[0] = bb[i]->clave[0];
        bbTraducir[i]->clave[1] = bb[i]->clave[1];
        bbTraducir[i]->clave[2] = bb[i]->clave[2];
        for(j=0;j<15;j++)
          bbTraducir[i]->valor[j] = 0;
      }
      bb[n]=0;
      bbTraducir[n]=0;
     
      /* comienzo de casos */
      tdt *tabla = tdt_crear("gande!");
      
      fputs( ">>> Test : agregar en bloque\n", pFile );
      
      tdt_agregarBloques(tabla,bb);
      tdt_imprimirTraducciones(tabla, pFile);
      fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
      fprintf(pFile,"\n");
      
      fputs( ">>> Test : borrar en bloque\n", pFile );
      
      tdt_borrarBloques(tabla,&(bb[n/2]));
      tdt_imprimirTraducciones(tabla, pFile);
      fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
      fprintf(pFile,"\n");
      
      fputs( ">>> Test : borrar bloques\n", pFile );
      
      for(i=0;i<n/4;i++)
        tdt_borrarBloque(tabla,bb[i]);
      tdt_imprimirTraducciones(tabla, pFile);
      fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
      
      fputs( ">>> Test : borrar individual\n", pFile );
      
      for(i=n/4;i<n/2;i++)
        tdt_borrar(tabla,bb[i]->clave);
      tdt_imprimirTraducciones(tabla, pFile);
      fprintf( pFile, "%i\n", tdt_cantidad(tabla) );  
      fprintf(pFile,"\n");
      
      fputs( ">>> Test : borrar y agregar aleatoriamente paso 1\n", pFile );
      
      for(i=0;i<n;i++) {
        tdt_agregarBloque(tabla,bb[rand()%n]);
        tdt_agregarBloque(tabla,bb[rand()%n]);
        tdt_borrar(tabla,bb[rand()%n]->clave);
      }
      tdt_imprimirTraducciones(tabla, pFile);
      printmaxmin(pFile, tabla);
      fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
      fprintf(pFile,"\n");
      
      fputs( ">>> Test : borrar y agregar aleatoriamente paso 2\n", pFile );
      
      for(i=0;i<n;i++) {
        tdt_agregarBloque(tabla,bb[rand()%n]);
        tdt_borrar(tabla,bb[rand()%n]->clave);
        tdt_borrar(tabla,bb[rand()%n]->clave);
        tdt_borrar(tabla,bb[rand()%n]->clave);
        tdt_borrar(tabla,bb[rand()%n]->clave);
      }
      tdt_imprimirTraducciones(tabla, pFile);
      printmaxmin(pFile, tabla);
      fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
      fprintf(pFile,"\n");
      
      fputs( ">>> Test : maximos y minimos\n", pFile );
      tdt_agregar(tabla,clave1,valorMax);
      printmaxmin(pFile, tabla);
      tdt_agregar(tabla,clave2,valorMin);
      printmaxmin(pFile, tabla);
      tdt_agregar(tabla,claveMax,valor1);
      printmaxmin(pFile, tabla);
      tdt_agregar(tabla,claveMin,valor2);
      printmaxmin(pFile, tabla);
      fprintf(pFile,"\n");
      
      fputs( ">>> Test : traducir bloques\n", pFile );
      
      tdt_traducirBloques(tabla,bbTraducir);
      fprintf( pFile, "%i\n", tdt_cantidad(tabla) );
      for(i=0;i<n;i++)
        printBloque(pFile,bbTraducir[i]);
      fprintf(pFile,"\n");
      
      fputs( ">>> Test : traducir en bloque\n", pFile );
      
      for(i=0;i<n;i++)
        for(j=0;j<15;j++)
          arrayBloquesTraducir[i].valor[j] = 0;
      for(i=0;i<n;i++)
        tdt_traducirBloque(tabla,&(arrayBloquesTraducir[i]));
      for(i=0;i<n;i++)
        printBloque(pFile,bbTraducir[i]);
      fprintf(pFile,"\n");
             
      fputs( ">>> Test : traducir bloques\n", pFile );

      for(i=0;i<n;i++)
        for(j=0;j<15;j++)
          arrayBloquesTraducir[i].valor[j] = 0;
      for(i=0;i<n;i++)
        tdt_traducir(tabla,(uint8_t*)&(arrayBloquesTraducir[i].clave),(uint8_t*)&(arrayBloquesTraducir[i].valor));
      for(i=0;i<n;i++)
        printBloque(pFile,bbTraducir[i]);
      fprintf(pFile,"\n");
      
      tdt_destruir(&tabla);
      
      free(bb);
      free(arrayBloques);
      free(bbTraducir);
      free(arrayBloquesTraducir);
      fclose( pFile );
}









