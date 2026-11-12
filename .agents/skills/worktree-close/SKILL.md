---
name: worktree-close
description: Cerrar el registro operativo de un worktree cuyo trabajo fue integrado o descartado por decision expresa, sin borrar automaticamente su rama o carpeta. Usar cuando {{APROBADOR}} confirme el cierre definitivo.
---

# Cerrar WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Verificar identidad, fila, Git, handoff y motivo: integrado o descartado. Si el trabajo no esta integrado y {{APROBADOR}} no autorizo descartarlo, no cerrar.
2. Buscar en `OWNERS.md` cedentes asociados: filas `inactivo` cuya responsabilidad contenga la marca normalizada `cedida total a WTxx; issue #n`, donde `WTxx` es el receptor que se está cerrando. No inferir por nombre, worker o similitud; si no hay marca clara, informar que no se encontraron cedentes asociados.
3. Para cada cedente asociado, verificar ruta, branch, `HEAD`, `git status --short` limpio y ausencia de merge/rebase/cherry-pick en curso. Leer su handoff vigente y la Issue referida para confirmar que no declara commits, cambios o pendientes no transferidos. Si hay cambios, operación Git inconclusa o pendientes no transferidos, no cerrar ese cedente: informar bloqueo y conservarlo `inactivo`.
4. Actualizar el handoff del WT que se cierra con resultado final, commits o integracion relevante, validaciones, cedentes cerrados o bloqueados y lineas afectadas. Conservar trazabilidad suficiente sin transcript. No escribir un nuevo handoff obligatorio para el cedente salvo que {{APROBADOR}} lo pida o haya información relevante que sólo pueda quedar allí.
5. Cambiar el estado del WT actual a `cerrado` y cambiar a `cerrado` los cedentes asociados que pasaron las verificaciones, con motivo `línea cerrada por receptor WTxx`. No reasignar filas ni reutilizar IDs. Avisar a los WT dependientes.
6. Si existe capacidad real de interfaz, renombrar el chat saliente como `XX_[WT]_[VERSIÓN]_[NOMBRE]` y archivarlo en la misma ejecución. No convertir el archivado en un segundo paso manual para preservar visibilidad del resumen: {{APROBADOR}} revisa el resumen desde archivados si lo necesita. Sólo entregar acción manual si la interfaz no permite archivar o si el archivado falla explícitamente, indicando el nombre exacto esperado. `worktree-close` no usa ni inventa prefijos `CL_...`: el estado `cerrado` vive en `OWNERS.md` y el chat archivado sigue siendo histórico `XX_...`. Informar por separado cualquier limpieza posible.

Cerrar no autoriza borrar worktree, rama, archivos o commits. Toda limpieza destructiva requiere una solicitud y verificacion independientes.
