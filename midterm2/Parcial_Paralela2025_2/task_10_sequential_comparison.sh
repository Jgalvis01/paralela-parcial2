#!/bin/bash

# ============================================================================
# TAREA 10: COMPARACIÓN DE ALGORITMOS SECUENCIALES
# ============================================================================
# Este script compila y ejecuta los tres algoritmos secuenciales (BFS, A*-h1, A*-h2)
# con el dataset de 42 puzzles y genera métricas comparativas en formato CSV
# ============================================================================

echo "========================================================"
echo "    TAREA 10: ANÁLISIS DE ALGORITMOS SECUENCIALES"
echo "========================================================"
echo ""

# Crear directorio para resultados
mkdir -p results/sequential_analysis

echo "📦 Compilando algoritmos secuenciales..."

# Compilar los tres algoritmos con métricas internas de timing
g++ -std=c++11 -O2 bsp_solver_nsize.cpp -o bsp_solver_metrics
g++ -std=c++11 -O2 h1_solver_nsize.cpp -o h1_solver_metrics  
g++ -std=c++11 -O2 h2_solver_nsize.cpp -o h2_solver_metrics

echo "✅ Compilación completada"
echo ""

# Función para ejecutar un algoritmo y generar métricas
run_algorithm() {
    local algorithm_name="$1"
    local executable="$2"
    local output_file="$3"
    
    echo "🔄 Ejecutando $algorithm_name con 42 puzzles..."
    
    start_time=$(date +%s.%N)
    ./$executable puzzles.txt 4 > "$output_file"
    end_time=$(date +%s.%N)
    
    # Calcular tiempo total usando aritmética de shell
    total_time=$(awk "BEGIN {printf \"%.3f\", $end_time - $start_time}")
    
    # Calcular estadísticas
    solved_count=$(tail -n +2 "$output_file" | grep -c "true")
    total_puzzles=$(tail -n +2 "$output_file" | wc -l)
    avg_time=$(tail -n +2 "$output_file" | awk -F',' '{sum+=$4; count++} END {if(count>0) printf "%.3f", sum/count; else print "0"}')
    avg_nodes=$(tail -n +2 "$output_file" | awk -F',' '{sum+=$5; count++} END {if(count>0) printf "%.0f", sum/count; else print "0"}')
    success_rate=$(awk "BEGIN {if($total_puzzles>0) printf \"%.2f\", $solved_count * 100 / $total_puzzles; else print \"0\"}")
    
    echo "   ✅ Completado en ${total_time}s"
    echo "   📊 Puzzles resueltos: $solved_count/$total_puzzles ($success_rate%)"
    echo "   ⏱️  Tiempo promedio: ${avg_time}ms"
    echo "   🌳 Nodos promedio: $avg_nodes"
    echo ""
}

echo "🎯 Ejecutando evaluación comparativa..."
echo ""

# Ejecutar cada algoritmo
run_algorithm "BFS" "bsp_solver_metrics" "results/sequential_analysis/BFS_results.csv"
run_algorithm "A*-h1" "h1_solver_metrics" "results/sequential_analysis/H1_results.csv"  
run_algorithm "A*-h2" "h2_solver_metrics" "results/sequential_analysis/H2_results.csv"

echo "📈 Generando análisis comparativo..."

# Crear archivo de resumen comparativo
cat > results/sequential_analysis/comparative_summary.csv << EOF
Algorithm,Total_Puzzles,Solved_Puzzles,Success_Rate_%,Avg_Time_ms,Avg_Nodes_Expanded,Min_Time_ms,Max_Time_ms,Std_Dev_Time
EOF

# Función para calcular estadísticas detalladas
calculate_stats() {
    local file="$1"
    local algorithm="$2"
    
    # Obtener datos numéricos (excluyendo header y puzzles no resueltos)
    tail -n +2 "$file" | grep "true" > temp_solved.csv
    
    if [ -s temp_solved.csv ]; then
        total_puzzles=$(tail -n +2 "$file" | wc -l)
        solved_puzzles=$(wc -l < temp_solved.csv)
        success_rate=$(awk "BEGIN {if($total_puzzles>0) printf \"%.2f\", $solved_puzzles * 100 / $total_puzzles; else print \"0\"}")
        
        # Calcular estadísticas de tiempo
        avg_time=$(awk -F',' '{sum+=$4; count++} END {printf "%.3f", sum/count}' temp_solved.csv)
        min_time=$(awk -F',' 'NR==1 {min=$4} {if($4<min) min=$4} END {printf "%.3f", min}' temp_solved.csv)
        max_time=$(awk -F',' 'NR==1 {max=$4} {if($4>max) max=$4} END {printf "%.3f", max}' temp_solved.csv)
        
        # Calcular estadísticas de nodos
        avg_nodes=$(awk -F',' '{sum+=$5; count++} END {printf "%.0f", sum/count}' temp_solved.csv)
        
        # Calcular desviación estándar de tiempo
        std_dev=$(awk -F',' -v avg="$avg_time" '{diff=$4-avg; sum_sq+=diff*diff; count++} END {printf "%.3f", sqrt(sum_sq/count)}' temp_solved.csv)
        
        echo "$algorithm,$total_puzzles,$solved_puzzles,$success_rate,$avg_time,$avg_nodes,$min_time,$max_time,$std_dev" >> results/sequential_analysis/comparative_summary.csv
    fi
    
    rm -f temp_solved.csv
}

# Generar estadísticas para cada algoritmo
calculate_stats "results/sequential_analysis/BFS_results.csv" "BFS"
calculate_stats "results/sequential_analysis/H1_results.csv" "A*-h1"
calculate_stats "results/sequential_analysis/H2_results.csv" "A*-h2"

echo "📊 Generando análisis por complejidad de puzzle..."

# Crear análisis por número de movimientos de solución
cat > results/sequential_analysis/complexity_analysis.csv << EOF
Algorithm,Moves_Range,Puzzle_Count,Avg_Time_ms,Avg_Nodes,Success_Rate_%
EOF

analyze_by_complexity() {
    local file="$1" 
    local algorithm="$2"
    
    echo "   Analizando $algorithm por complejidad..."
    
    # Puzzles simples (≤4 movimientos)
    tail -n +2 "$file" | awk -F',' '$3<=4 && $6=="true"' > temp_simple.csv
    if [ -s temp_simple.csv ]; then
        count=$(wc -l < temp_simple.csv)
        avg_time=$(awk -F',' '{sum+=$4; cnt++} END {if(cnt>0) printf "%.3f", sum/cnt; else print "0"}' temp_simple.csv)
        avg_nodes=$(awk -F',' '{sum+=$5; cnt++} END {if(cnt>0) printf "%.0f", sum/cnt; else print "0"}' temp_simple.csv)
        total_simple=$(tail -n +2 "$file" | awk -F',' '$3<=4' | wc -l)
        success_rate=$(awk "BEGIN {if($total_simple>0) printf \"%.2f\", $count * 100 / $total_simple; else print \"0\"}")
        echo "$algorithm,Simple(≤4),$count,$avg_time,$avg_nodes,$success_rate" >> results/sequential_analysis/complexity_analysis.csv
    fi
    
    # Puzzles medios (5-8 movimientos)
    tail -n +2 "$file" | awk -F',' '$3>=5 && $3<=8 && $6=="true"' > temp_medium.csv
    if [ -s temp_medium.csv ]; then
        count=$(wc -l < temp_medium.csv)
        avg_time=$(awk -F',' '{sum+=$4; cnt++} END {if(cnt>0) printf "%.3f", sum/cnt; else print "0"}' temp_medium.csv)
        avg_nodes=$(awk -F',' '{sum+=$5; cnt++} END {if(cnt>0) printf "%.0f", sum/cnt; else print "0"}' temp_medium.csv)
        total_medium=$(tail -n +2 "$file" | awk -F',' '$3>=5 && $3<=8' | wc -l)
        success_rate=$(awk "BEGIN {if($total_medium>0) printf \"%.2f\", $count * 100 / $total_medium; else print \"0\"}")
        echo "$algorithm,Medium(5-8),$count,$avg_time,$avg_nodes,$success_rate" >> results/sequential_analysis/complexity_analysis.csv
    fi
    
    # Puzzles complejos (>8 movimientos)
    tail -n +2 "$file" | awk -F',' '$3>8 && $6=="true"' > temp_complex.csv
    if [ -s temp_complex.csv ]; then
        count=$(wc -l < temp_complex.csv)
        avg_time=$(awk -F',' '{sum+=$4; cnt++} END {if(cnt>0) printf "%.3f", sum/cnt; else print "0"}' temp_complex.csv)
        avg_nodes=$(awk -F',' '{sum+=$5; cnt++} END {if(cnt>0) printf "%.0f", sum/cnt; else print "0"}' temp_complex.csv)
        total_complex=$(tail -n +2 "$file" | awk -F',' '$3>8' | wc -l)
        success_rate=$(awk "BEGIN {if($total_complex>0) printf \"%.2f\", $count * 100 / $total_complex; else print \"0\"}")
        echo "$algorithm,Complex(>8),$count,$avg_time,$avg_nodes,$success_rate" >> results/sequential_analysis/complexity_analysis.csv
    fi
    
    rm -f temp_simple.csv temp_medium.csv temp_complex.csv
}

analyze_by_complexity "results/sequential_analysis/BFS_results.csv" "BFS"
analyze_by_complexity "results/sequential_analysis/H1_results.csv" "A*-h1"
analyze_by_complexity "results/sequential_analysis/H2_results.csv" "A*-h2"

echo "📋 Mostrando resumen comparativo:"
echo ""
if [ -f results/sequential_analysis/comparative_summary.csv ]; then
    # Usar awk para formatear como tabla
    awk -F',' 'NR==1 {printf "%-10s %-6s %-6s %-12s %-12s %-12s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9} 
               NR>1 {printf "%-10s %-6s %-6s %-12s %-12s %-12s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9}' results/sequential_analysis/comparative_summary.csv
else
    echo "❌ No se pudo generar el resumen comparativo"
fi
echo ""

echo "📊 Análisis por complejidad:"
echo ""
if [ -f results/sequential_analysis/complexity_analysis.csv ]; then
    awk -F',' 'NR==1 {printf "%-10s %-15s %-6s %-12s %-12s %-12s\n", $1, $2, $3, $4, $5, $6} 
               NR>1 {printf "%-10s %-15s %-6s %-12s %-12s %-12s\n", $1, $2, $3, $4, $5, $6}' results/sequential_analysis/complexity_analysis.csv
else
    echo "❌ No se pudo generar el análisis por complejidad"
fi
echo ""

echo "========================================================"
echo "    RESULTADOS DE TAREA 10"
echo "========================================================"
echo ""
echo "✅ Archivos generados:"
echo "   📄 BFS_results.csv - Resultados detallados BFS"
echo "   📄 H1_results.csv - Resultados detallados A*-h1"  
echo "   📄 H2_results.csv - Resultados detallados A*-h2"
echo "   📄 comparative_summary.csv - Resumen comparativo"
echo "   📄 complexity_analysis.csv - Análisis por complejidad"
echo ""
echo "📊 Para generar gráficos, use estos datos CSV con herramientas como:"
echo "   - Python matplotlib/seaborn"
echo "   - R ggplot2"
echo "   - Excel/LibreOffice Calc"
echo ""
echo "🎯 Métricas clave obtenidas:"
echo "   - Tiempo de ejecución por puzzle"
echo "   - Número de nodos expandidos"
echo "   - Tasa de éxito por algoritmo"
echo "   - Análisis por complejidad del puzzle"
echo ""
echo "✅ TAREA 10 COMPLETADA EXITOSAMENTE"
echo "========================================================"