#!/bin/bash

# ============================================================================
# TAREA 1-7: IMPLEMENTACIONES BÁSICAS DEL SLIDING PUZZLE
# ============================================================================
# Este script ejecuta las funcionalidades básicas del sliding puzzle:
# - Imprimir tablero
# - Mostrar movimientos disponibles
# - Verificar posiciones disponibles
# ============================================================================

echo "========================================================"
echo "    SLIDING PUZZLE - FUNCIONALIDADES BÁSICAS"
echo "========================================================"
echo ""

# Crear directorio para resultados
mkdir -p results/basic_functionality

# Compilar todas las herramientas básicas
echo "📦 Compilando herramientas básicas..."
g++ -std=c++11 -O2 board_printer.cpp -o board_printer
g++ -std=c++11 -O2 board_moves.cpp -o board_moves  
g++ -std=c++11 -O2 board_available.cpp -o board_available

echo "✅ Compilación completada"
echo ""

# Función para mostrar información de un tablero
show_board_info() {
    local board="$1"
    local name="$2"
    
    echo "----------------------------------------"
    echo "🔍 Analizando: $name"
    echo "Tablero: $board"
    echo ""
    
    echo "📋 TABLERO FORMATEADO:"
    echo "4 $board" | ./board_printer
    echo ""
    
    echo "📍 POSICIONES DISPONIBLES:"
    echo "4 $board" | ./board_available
    echo ""
    
    # Demostrar movimientos disponibles
    echo "🎯 DEMOSTRANDO MOVIMIENTOS DISPONIBLES:"
    
    # Obtener movimientos disponibles
    available_moves=$(echo "4 $board" | ./board_available)
    
    # Para cada movimiento disponible, mostrar antes y después
    while IFS= read -r move; do
        if [ ! -z "$move" ]; then
            echo "   📌 Movimiento: $move"
            echo "      ANTES:"
            echo "4 $board" | ./board_printer | sed 's/^/      /'
            echo "      DESPUÉS:"
            echo "4 $board $move" | ./board_moves | sed 's/^/      /'
            echo ""
        fi
    done <<< "$available_moves"
}

# Ejemplos de tableros para demostración
echo "DEMOSTRANDO FUNCIONALIDADES CON EJEMPLOS:"
echo ""

# Tablero ordenado (estado objetivo)
show_board_info "ABCDEFGHIJKLMNO#" "Estado Objetivo"

echo "========================================================"
echo "    PRUEBA CON PRIMEROS 2 PUZZLES DEL DATASET"
echo "========================================================"
echo ""

# Procesar primeros 2 puzzles del archivo
counter=1
while IFS= read -r line && [ $counter -le 2 ]; do
    if [ ! -z "$line" ]; then
        show_board_info "$line" "Puzzle #$counter del dataset"
        counter=$((counter + 1))
    fi
done < puzzles.txt
