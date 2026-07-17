# Codigo

Esta carpeta contiene los scripts utilizados para el procesamiento, analisis y generacion de resultados del proyecto.

El codigo se encuentra organizado de acuerdo con el entorno de trabajo empleado y con la funcion que cumple dentro del flujo metodologico del proyecto.

## Estructura de la carpeta

- `matlab/`: contiene los scripts principales de simulacion, calibracion, analisis espacial y generacion de mapas de campo electrico.
- `python_colab/`: contiene scripts desarrollados o ejecutados en Google Colab para tareas auxiliares de procesamiento de datos.

## Codigo en MATLAB

Los scripts en MATLAB se emplean principalmente para la estimacion del campo electrico, la calibracion del modelo de propagacion y la generacion de mapas de calor sobre el area de estudio.

El script principal del proyecto es:

- `matlab/mapa_calor_hibrido_colormap_folium.m`

Este archivo integra el procesamiento de datos, la aplicacion del modelo calibrado y la visualizacion espacial de los resultados.

## Codigo en Python / Google Colab

Los scripts en Python se utilizan como apoyo para el tratamiento de archivos de medicion, conversion de coordenadas y organizacion de datos procesados.

Actualmente se incluye:

- `python_colab/cordenadas.py`: script empleado para generar archivos de coordenadas asociados a los puntos de medicion.

## Insumos cartograficos

La carpeta `matlab/insumos_cartograficos/` contiene los archivos geoespaciales utilizados como soporte para la representacion del campus y la ubicacion de los puntos de medicion.

Estos insumos son necesarios para que el codigo de MATLAB funcione correctamente en un equipo local. La ausencia de estos archivos puede generar errores durante la carga del escenario, la ubicacion espacial de los puntos de medicion o la generacion de mapas de calor.

## Consideraciones

Se recomienda conservar la estructura de carpetas del repositorio, ya que algunos scripts dependen de rutas relativas o de la organizacion establecida para los datos, insumos y resultados.
