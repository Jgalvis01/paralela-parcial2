# Resumen de Correcciones en informe_parcial.tex

## Datos Actualizados (Task 11)

### Métricas de Speedup Corregidas:
- **Tiempo base secuencial:** 2516.17 ms (corregido de 2002.82 ms)
- **2 hilos:** Speedup 0.915 (45.75% eficiencia) - tiempo paralelo: 2749.22 ms
- **4 hilos:** Speedup 0.695 (17.38% eficiencia) - tiempo paralelo: 3620.17 ms  
- **8 hilos:** Speedup 0.310 (3.88% eficiencia) - tiempo paralelo: 8112.71 ms

### Overhead Paralelo Actualizado:
- **2 hilos:** 2,982.27 ms
- **4 hilos:** 11,964.51 ms
- **8 hilos:** 62,385.54 ms (crecimiento exponencial de 20.9x respecto a 2 hilos)

### Balance de Carga (4 hilos) Corregido:
- Hilo 0: 18 puzzles, 712.63 ms (39.59 ms/puzzle)
- Hilo 1: 8 puzzles, 987.65 ms (123.46 ms/puzzle)
- Hilo 2: 9 puzzles, 910.16 ms (101.13 ms/puzzle)
- Hilo 3: 7 puzzles, 1009.73 ms (144.25 ms/puzzle)

### Balance de Carga (8 hilos) Actualizado:
- Máxima varianza: 50.70 ms/puzzle (hilo 0) vs 408.78 ms/puzzle (hilo 2)
- Factor de desbalance: 8.07x

## Problema Clave Identificado y Documentado

### Diferencia BFS Secuencial vs Paralelo:
- **BFS Secuencial:** 40/42 puzzles resueltos (95.24%)
  - Límite: MAX_STATES = 1,000,000
  - Fallos: puzzles 40 y 41

- **BFS Paralelo:** 37/42 puzzles resueltos (88.10%)
  - Límites: MAX_STATES = 1,000,000 Y MAX_QUEUE = 200,000
  - 5 puzzles fallaron por límite de cola más restrictivo
  - Justificación: protección contra desbordamiento de memoria en procesamiento paralelo

## Secciones Añadidas

### 1. Nota Metodológica en Análisis de Resultados Negativos:
- Explica que tiempos internos incluyen baseline secuencial + ejecución paralela
- Aclara por qué tiempo "paralelo" con 1 hilo = baseline secuencial
- Documenta la medición con `omp_get_wtime()`

### 2. Diferenciación de Implementaciones BFS:
- Subsección en "Análisis Detallado por Algoritmo"
- Explica límites diferentes entre versiones
- Justifica tasa de éxito reducida en versión paralela

### 3. Anexo C: Notas Metodológicas sobre Medición de Tiempo:
- **Tiempos Reportados:** Explica las dos fases (secuencial + paralela)
- **Cálculo de Overhead:** Fórmula y qué captura
- **Diferencias con Medición Externa:** Por qué tiempos shell ≠ tiempos internos

## Actualizaciones en Análisis

### Ley de Amdahl Revisada:
- Fracción paralelizable ajustada: P ≈ 0.35 (de 0.40)
- Considera 11.9% puzzles que no se resuelven
- Speedup teórico máximo: 1.18 (2 hilos), 1.30 (4 hilos), 1.39 (8 hilos)
- Nota: resultados reales aún peores que teoría

### Heterogeneidad de Carga Corregida:
- 37 puzzles resueltos efectivamente (no 42)
- 5 puzzles no resueltos introducen variabilidad
- Distribución de tiempo actualizada con timeouts

### Limitaciones del Estudio Expandidas:
- Añadido: límite MAX_QUEUE reduce tasa éxito
- Añadido: heterogeneidad extrema (5 puzzles = 95% tiempo)
- Añadido: recomendación de 1000+ puzzles para evaluación válida

## Conclusiones Ajustadas

### BFS inviable documentado con precisión:
- Secuencial: 4.76% fallos (2/42)
- Paralelo: 11.90% fallos (5/42)
- Útil solo para profundidad ≤ 8

### Paralelización:
- Speedup subunitario en todos los casos (no solo "consistentemente <1")
- Crecimiento exponencial de overhead documentado
- Tasa de éxito reducida añadida como limitación adicional

## Consistencia de Datos

✅ Todos los números ahora coinciden con output de `task_11_parallel_analysis.sh`
✅ Explicación clara de discrepancias entre secuencial y paralelo
✅ Metodología de medición documentada en anexo
✅ Limitaciones reconocidas explícitamente

## Compilación

El documento está listo para compilar con:
```bash
pdflatex informe_parcial.tex
pdflatex informe_parcial.tex  # Segunda pasada para referencias
```

No requiere bibtex (referencias en sección manual).
