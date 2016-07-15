#!/bin/bash
clear

echo " "
echo "**Compilando"

make tester
if [ $? -ne 0 ]; then
  echo "  **Error de compilacion"
  exit 1
fi

echo " "
echo "**Corriendo Valgrind"

valgrind --show-reachable=yes --leak-check=full --error-exitcode=1 ./tester
if [ $? -ne 0 ]; then
  echo "  **Error de memoria"
  exit 1
fi

echo " "
echo "**Corriendo diferencias con la catedra"

DIFFER="diff -d"
ERRORDIFF=0

$DIFFER salida.caso.chico.txt Catedra.salida.caso.chico.txt > /tmp/diff1
if [ $? -ne 0 ]; then
  echo "  **Discrepancia en el caso CHICO: salida.caso.chico.txt vs Catedra.salida.caso.chico.txt"
  ERRORDIFF=1
fi

$DIFFER salida.caso.grande.txt Catedra.salida.caso.grande.txt > /tmp/diff2
if [ $? -ne 0 ]; then
  echo "  **Discrepancia en el caso GRANDE: salida.caso.grande.txt vs Catedra.salida.caso.grande.txt"
  ERRORDIFF=1
fi

echo " "
if [ $ERRORDIFF -eq 0 ]; then
  echo "**Todos los tests pasan"
fi
echo " "
