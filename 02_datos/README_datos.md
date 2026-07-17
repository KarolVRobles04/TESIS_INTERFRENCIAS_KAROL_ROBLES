# Datos

Esta carpeta contiene los conjuntos de datos empleados en el desarrollo del proyecto, incluyendo las mediciones originales de campo y los archivos derivados del procesamiento posterior.

La informacion se encuentra organizada de forma que sea posible mantener la trazabilidad entre los datos capturados, los datos procesados y los resultados obtenidos para cada banda de frecuencia analizada.

## Estructura de la carpeta

- `datos_crudos/`: contiene los archivos originales obtenidos durante las campanas de medicion.
- `datos_procesados/`: contiene los archivos generados a partir del tratamiento, conversion y organizacion de los datos crudos.

## Datos crudos

Los datos crudos corresponden a las mediciones realizadas en campo para las bandas FM, LTE y TDT. Estos archivos incluyen registros de medicion, capturas de espectro y archivos auxiliares asociados a cada punto evaluado.

La informacion se encuentra organizada por banda:

- `datos_crudos/mediciones/FM/`
- `datos_crudos/mediciones/LTE/`
- `datos_crudos/mediciones/TDT/`

## Datos procesados

Los datos procesados corresponden a archivos obtenidos despues de aplicar rutinas de organizacion y conversion sobre los datos originales. En esta carpeta se incluyen archivos de coordenadas, resultados intermedios y figuras generadas durante el procesamiento.

## Bandas de analisis

| Banda | Frecuencia de referencia | Descripcion |
| --- | ---: | --- |
| FM | 101.7 MHz | Banda de radiodifusion sonora FM considerada dentro del analisis experimental. |
| LTE | 877 MHz | Banda asociada a servicios moviles comerciales evaluada mediante mediciones de campo. |
| TDT | 479 MHz | Banda correspondiente a television digital terrestre incluida en la campana de medicion. |

## Consideraciones

La estructura de archivos debe conservarse para mantener la correspondencia entre los puntos de medicion, los archivos procesados y los resultados generados.

Los datos almacenados en esta carpeta sirven como base para la calibracion, validacion y comparacion de los modelos empleados en el proyecto.
