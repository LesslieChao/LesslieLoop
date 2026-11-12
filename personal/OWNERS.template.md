# OWNERS · estado personal del proyecto

- Identidad estable: completar desde `PROJECT.md`
- Última actualización: fecha y worker que realizó el cambio

| WT | Nombre | Worker | Ruta de la carpeta | Branch | Responsabilidad | Estado |
| --- | --- | --- | --- | --- | --- | --- |

Estados: `activo`, `inactivo`, `cerrado`. Un WT pertenece a un worker y conserva su carpeta al rotar chat. Crear otro WT para cambiar de worker; actualizar ambas filas y avisar a los afectados cuando el trabajo integrado o descartado cierre una línea.

Puede haber cualquier cantidad de filas históricas, pero nunca más de cinco en estado `activo` al mismo tiempo. Antes de crear o reactivar, contar mecánicamente las filas activas; con cinco, pausar o cerrar otra antes de continuar.

La tabla comienza vacía. Agregar filas únicamente después de verificar la existencia de carpeta y rama. Usar ID único, ruta absoluta y responsabilidad confirmada. Conservar las filas cerradas; no reutilizar sus ID. Antes de guardar, releer el registro para preservar cambios concurrentes y modificar sólo las filas implicadas.

La carpeta de cada WT usa `WTxx - Título`: ID de dos dígitos, espacio-guion-espacio y un título humano breve. El título no incluye worker, estado, versión del handoff ni nombre de chat. La carpeta permanece estable cuando cambia el owner.
