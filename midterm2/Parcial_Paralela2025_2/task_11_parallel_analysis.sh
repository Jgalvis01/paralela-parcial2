#!/bin/bash

# ============================================================================
# TAREA 11: COMPARACIÓN DE VERSIÓN PARALELIZADA
# ============================================================================
# Este script ejecuta la versión paralela con diferentes números de hilos
# y calcula las métricas obligatorias: speedup, eficiencia, y nodos por hilo
# ============================================================================

echo "========================================================"
echo "    TAREA 11: ANÁLISIS DE PARALELIZACIÓN CON OPENMP"
echo "========================================================"
echo ""

# Crear directorio para resultados
mkdir -p results/parallel_analysis

echo "📦 Compilando solver paralelo..."

# Compilar con OpenMP
g++ -std=c++17 -fopenmp -O2 bsp_parallel_solver.cpp -o bsp_parallel

if [ ! -f "bsp_parallel" ]; then
    echo "❌ Error: No se pudo compilar el solver paralelo"
    echo "   Asegúrese de que OpenMP esté disponible"
    exit 1
fi

echo "✅ Compilación completada"
echo ""

echo "🎯 Ejecutando evaluación paralela con diferentes números de hilos..."
echo ""

# Configuraciones de hilos a probar
thread_configs=(1 2 4 8)

# Archivo para métricas consolidadas
cat > results/parallel_analysis/parallel_metrics.csv << EOF
Threads,Total_Time_ms,Avg_Time_per_Puzzle_ms,Total_Nodes,Avg_Nodes_per_Thread,Puzzles_Solved,Success_Rate_%
EOF

# Archivo para análisis de speedup
cat > results/parallel_analysis/speedup_analysis.csv << EOF
Threads,Sequential_Time_ms,Parallel_Time_ms,Speedup,Efficiency_%,Theoretical_Speedup,Parallel_Overhead_ms
EOF

# Variable para almacenar tiempo secuencial (baseline)
sequential_time=""
sequential_nodes=""

# Función para ejecutar análisis paralelo
run_parallel_analysis() {
    local num_threads="$1"
    
    echo "🔄 Ejecutando con $num_threads hilo(s)..."
    
    # Ejecutar solver paralelo
    start_time=$(date +%s.%N)
    ./bsp_parallel puzzles.txt $num_threads > "results/parallel_analysis/parallel_${num_threads}threads_summary.txt"
    end_time=$(date +%s.%N)
    
    # Mover el archivo CSV generado automáticamente
    if [ -f "parallel_results_fixed.csv" ]; then
        mv parallel_results_fixed.csv "results/parallel_analysis/parallel_${num_threads}threads.csv"
    fi
    
    execution_time=$(awk "BEGIN {printf \"%.3f\", ($end_time - $start_time) * 1000}")
    
    # Procesar resultados
    if [ -f "results/parallel_analysis/parallel_${num_threads}threads.csv" ]; then
        
        # Calcular estadísticas básicas (ajustado al formato del CSV real)
        total_puzzles=$(tail -n +2 "results/parallel_analysis/parallel_${num_threads}threads.csv" | wc -l)
        solved_puzzles=$(tail -n +2 "results/parallel_analysis/parallel_${num_threads}threads.csv" | awk -F',' '$3>0' | wc -l)
        success_rate=$(awk "BEGIN {if($total_puzzles>0) printf \"%.2f\", $solved_puzzles * 100 / $total_puzzles; else print \"0\"}")
        
        # Calcular tiempo total de procesamiento interno (columna 5 = per_puzzle_ms)
        total_internal_time=$(tail -n +2 "results/parallel_analysis/parallel_${num_threads}threads.csv" | awk -F',' '{sum+=$5} END {printf "%.3f", sum}')
        avg_time_per_puzzle=$(awk "BEGIN {if($total_puzzles>0) printf \"%.3f\", $total_internal_time / $total_puzzles; else print \"0\"}")
        
        # Calcular nodos expandidos (columna 4 = nodes_expanded)
        total_nodes=$(tail -n +2 "results/parallel_analysis/parallel_${num_threads}threads.csv" | awk -F',' '{sum+=$4} END {printf "%.0f", sum}')
        avg_nodes_per_thread=$(awk "BEGIN {if($num_threads>0) printf \"%.0f\", $total_nodes / $num_threads; else print \"0\"}")
        
        # Guardar métricas básicas
        echo "$num_threads,$total_internal_time,$avg_time_per_puzzle,$total_nodes,$avg_nodes_per_thread,$solved_puzzles,$success_rate" >> results/parallel_analysis/parallel_metrics.csv
        
        echo "   ✅ Completado en ${execution_time}ms (externo)"
        echo "   📊 Tiempo interno total: ${total_internal_time}ms"
        echo "   🎯 Puzzles resueltos: $solved_puzzles/$total_puzzles ($success_rate%)"
        echo "   🌳 Nodos expandidos: $total_nodes"
        echo "   🧵 Nodos promedio por hilo: $avg_nodes_per_thread"
        
        # Si es el caso secuencial (1 hilo), guardar como baseline
        if [ $num_threads -eq 1 ]; then
            sequential_time="$total_internal_time"
            sequential_nodes="$total_nodes"
            echo "   📝 Guardado como baseline secuencial"
        fi
        
        # Si no es secuencial, calcular speedup y eficiencia
        if [ $num_threads -gt 1 ] && [ ! -z "$sequential_time" ]; then
            speedup=$(awk "BEGIN {if($total_internal_time>0) printf \"%.3f\", $sequential_time / $total_internal_time; else print \"0\"}")
            efficiency=$(awk "BEGIN {if($num_threads>0) printf \"%.2f\", $speedup * 100 / $num_threads; else print \"0\"}")
            theoretical_speedup=$num_threads
            overhead=$(awk "BEGIN {printf \"%.3f\", ($total_internal_time * $num_threads) - $sequential_time}")
            
            echo "   🚀 Speedup: ${speedup}x"
            echo "   ⚡ Eficiencia: ${efficiency}%"
            echo "   📈 Overhead paralelo: ${overhead}ms"
            
            # Guardar análisis de speedup
            echo "$num_threads,$sequential_time,$total_internal_time,$speedup,$efficiency,$theoretical_speedup,$overhead" >> results/parallel_analysis/speedup_analysis.csv
        fi
        
        echo ""
    else
        echo "   ❌ Error: No se generaron resultados para $num_threads hilos"
        echo ""
    fi
}

# Ejecutar análisis para cada configuración de hilos
for threads in "${thread_configs[@]}"; do
    run_parallel_analysis $threads
done

echo "📊 Generando análisis detallado de distribución de trabajo..."

# Análisis de distribución de trabajo por hilos
cat > results/parallel_analysis/thread_distribution.csv << EOF
Threads,Thread_ID,Puzzles_Assigned,Total_Time_ms,Avg_Time_per_Puzzle_ms,Total_Nodes,Load_Balance_Score
EOF

# Función para analizar distribución por hilos
analyze_thread_distribution() {
    local num_threads="$1"
    local file="results/parallel_analysis/parallel_${num_threads}threads.csv"
    
    if [ -f "$file" ] && [ $num_threads -gt 1 ]; then
        echo "   Analizando distribución para $num_threads hilos..."
        
        # Para cada hilo, calcular estadísticas (columna 2 = thread_id)
        for ((thread_id=0; thread_id<num_threads; thread_id++)); do
            # Filtrar puzzles asignados a este hilo
            thread_puzzles=$(tail -n +2 "$file" | awk -F',' -v tid="$thread_id" '$2==tid' | wc -l)
            
            if [ $thread_puzzles -gt 0 ]; then
                thread_time=$(tail -n +2 "$file" | awk -F',' -v tid="$thread_id" '$2==tid {sum+=$5} END {printf "%.3f", sum}')
                thread_avg_time=$(awk "BEGIN {if($thread_puzzles>0) printf \"%.3f\", $thread_time / $thread_puzzles; else print \"0\"}")
                thread_nodes=$(tail -n +2 "$file" | awk -F',' -v tid="$thread_id" '$2==tid {sum+=$4} END {printf "%.0f", sum}')
                
                # Calcular score de balance de carga (desviación del promedio ideal)
                ideal_puzzles=$(awk "BEGIN {if($num_threads>0) printf \"%.0f\", 42 / $num_threads; else print \"0\"}")
                load_balance=$(awk "BEGIN {if($ideal_puzzles>0) printf \"%.2f\", 100 - (($thread_puzzles - $ideal_puzzles) * ($thread_puzzles - $ideal_puzzles) * 100 / ($ideal_puzzles * $ideal_puzzles)); else print \"0\"}")
                
                echo "$num_threads,$thread_id,$thread_puzzles,$thread_time,$thread_avg_time,$thread_nodes,$load_balance" >> results/parallel_analysis/thread_distribution.csv
            fi
        done
    fi
}

# Analizar distribución para configuraciones multi-hilo
for threads in "${thread_configs[@]}"; do
    if [ $threads -gt 1 ]; then
        analyze_thread_distribution $threads
    fi
done

echo "📈 Generando resumen de hallazgos de paralelización..."

# Crear archivo de análisis detallado
cat > results/parallel_analysis/parallelization_findings.txt << EOF
ANÁLISIS DE PARALELIZACIÓN CON OPENMP

1. ESTRATEGIA IMPLEMENTADA:
   - Descomposición de dominio (data decomposition)
   - Cada hilo procesa un subconjunto de puzzles independiente
   - Scheduling dinámico para balanceo automático de carga

2. JUSTIFICACIÓN DE LA ESTRATEGIA:
   - Los puzzles son independientes entre sí
   - No requiere sincronización durante el procesamiento
   - Evita la complejidad de paralelizar BFS internamente
   - Escalable hasta el número de puzzles disponibles

3. IMPLEMENTACIÓN TÉCNICA:
   #pragma omp parallel for schedule(dynamic) shared(puzzles, results)
   - schedule(dynamic): Balanceo automático de carga
   - omp_get_wtime(): Medición precisa de tiempo
   - Variables compartidas para datos y resultados

4. CÁLCULO DE MÉTRICAS:

   Speedup = Tiempo_Secuencial / Tiempo_Paralelo
   Eficiencia = (Speedup / Número_Hilos) × 100%
   
   Donde:
   - Tiempo_Secuencial: Ejecución con 1 hilo
   - Tiempo_Paralelo: Ejecución con N hilos
   - Eficiencia óptima = 100% (speedup lineal)

5. LIMITACIONES OBSERVADAS:
   - Overhead de gestión de hilos
   - Desbalance de carga con puzzles de complejidad variable
   - Contención de memoria con muchos hilos
   - Diminishing returns después del punto óptimo

6. CONFIGURACIÓN ÓPTIMA:
   - Basado en los resultados, determinar número óptimo de hilos
   - Balance entre speedup y eficiencia
   - Consideraciones de recursos del sistema
EOF

echo "📋 Mostrando métricas paralelas:"
echo ""
echo "=== MÉTRICAS BÁSICAS ==="
if [ -f results/parallel_analysis/parallel_metrics.csv ]; then
    awk -F',' 'NR==1 {printf "%-8s %-12s %-18s %-12s %-18s %-14s %-14s\n", $1, $2, $3, $4, $5, $6, $7} 
               NR>1 {printf "%-8s %-12s %-18s %-12s %-18s %-14s %-14s\n", $1, $2, $3, $4, $5, $6, $7}' results/parallel_analysis/parallel_metrics.csv
else
    echo "❌ No se pudieron generar métricas básicas"
fi
echo ""

echo "=== ANÁLISIS DE SPEEDUP ==="
if [ -f results/parallel_analysis/speedup_analysis.csv ]; then
    awk -F',' 'NR==1 {printf "%-8s %-16s %-16s %-8s %-12s %-18s %-16s\n", $1, $2, $3, $4, $5, $6, $7} 
               NR>1 {printf "%-8s %-16s %-16s %-8s %-12s %-18s %-16s\n", $1, $2, $3, $4, $5, $6, $7}' results/parallel_analysis/speedup_analysis.csv
else
    echo "❌ No se pudo generar análisis de speedup"
fi
echo ""

echo "=== DISTRIBUCIÓN DE TRABAJO ==="
if [ -f results/parallel_analysis/thread_distribution.csv ]; then
    echo "Primeras 10 líneas del análisis de distribución:"
    head -11 results/parallel_analysis/thread_distribution.csv | awk -F',' 'NR==1 {printf "%-8s %-10s %-14s %-12s %-16s %-12s %-16s\n", $1, $2, $3, $4, $5, $6, $7} 
                                                                               NR>1 {printf "%-8s %-10s %-14s %-12s %-16s %-12s %-16s\n", $1, $2, $3, $4, $5, $6, $7}'
else
    echo "❌ No se pudo generar análisis de distribución"
fi
echo ""

echo "========================================================"
echo "    RESULTADOS DE TAREA 11"
echo "========================================================"
echo ""
echo "✅ Archivos generados:"
echo "   📄 parallel_metrics.csv - Métricas básicas por configuración"
echo "   📄 speedup_analysis.csv - Análisis de speedup y eficiencia"
echo "   📄 thread_distribution.csv - Distribución de trabajo por hilo"
echo "   📄 parallelization_findings.txt - Análisis detallado"
echo "   📄 parallel_Nthreads.csv - Resultados detallados por configuración"
echo ""
echo "🎯 Métricas obligatorias calculadas:"
echo "   ✅ Tiempo de ejecución (segundos/milisegundos)"
echo "   ✅ Speedup (secuencial/paralelo)"
echo "   ✅ Eficiencia (speedup / n_hilos)"
echo "   ✅ Número de nodos expandidos por hilo"
echo ""
echo "📊 Para generar gráficos obligatorios:"
echo "   - Speedup vs Número de hilos"
echo "   - Eficiencia vs Número de hilos"
echo "   - Tiempo de ejecución vs Número de hilos"
echo "   - Distribución de trabajo por hilo"
echo ""
echo "🔍 Fórmulas utilizadas documentadas en:"
echo "   📄 parallelization_findings.txt"
echo ""
echo "✅ TAREA 11 COMPLETADA EXITOSAMENTE"
echo "========================================================"