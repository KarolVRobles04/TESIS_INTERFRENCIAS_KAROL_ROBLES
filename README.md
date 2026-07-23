# Trabajo de Grado - Deteccion de interferencias en bandas comerciales del espectro radioelectrico

Este repositorio contiene los datos, codigos, resultados y documentos asociados al trabajo de grado titulado:

**Diseno y validacion de una metodologia para la deteccion de interferencias en bandas comerciales del espectro radioelectrico, mediante mediciones y analisis dentro del campus central de la Universidad Industrial de Santander.**

## Estructura del repositorio

- `01_documento_tesis/`: documento de tesis en LaTeX y versiones PDF.
- `02_datos/`: datos crudos y procesados de las mediciones.
- `03_codigo/`: scripts de simulacion, procesamiento y validacion.
- `04_resultados/`: tablas, metricas y figuras generadas.
- `05_anexos/`: evidencia complementaria del proceso experimental.


## Acceso a anexos

Los evaluadores pueden consultar el instructivo de acceso a los anexos en:

- `05_anexos/INSTRUCTIVO_ACCESO_ANEXOS.md`

## Modelo empleado

Para la estimacion del campo electrico se emplea un modelo Log-Distance calibrado, con consideracion de perdidas adicionales por entorno y apoyo de insumos cartograficos del campus UIS.

El script principal disponible actualmente es:

- `03_codigo/matlab/mapa_calor_hibrido_colormap_folium.m`

## Resultados actuales

Los resultados disponibles corresponden a la calibracion del modelo para tres bandas evaluadas:

| Banda | Frecuencia | Puntos validos | MAE calibrado | RMSE calibrado |
| --- | ---: | ---: | ---: | ---: |
| FM | 101.7 MHz | 8 | 5.33 dB | 6.17 dB |
| LTE | 877 MHz | 8 | 1.11 dB | 1.52 dB |
| TDT | 469 MHz | 6 | 2.25 dB | 2.66 dB |

Las tablas se encuentran organizadas por banda en `04_resultados/tablas/` y las figuras disponibles en `04_resultados/figuras/`.

## Autores

- Johann David Vanegas Archila
- Karol Vaneza Robles Canizales
