---
name: worktree-close
description: Cierra el registro operativo de un worktree integrado o descartado por decisión expresa, sin borrar automáticamente rama o carpeta.
argument-hint: "[WTxx] [integrado|descartado]"
disable-model-invocation: true
---

# Cerrar WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Verificá identidad, fila, Git, handoff y motivo. Si no está integrado y {{APROBADOR}} no autorizó descartarlo, no cierres.
2. Buscá en `OWNERS.md` cedentes asociados: filas `inactivo` cuya responsabilidad contenga la marca normalizada `cedida total a WTxx; issue #n`, donde `WTxx` es el receptor que estás cerrando. No infieras por nombre, worker o similitud; si no hay marca clara, informá que no encontraste cedentes asociados.
3. Para cada cedente asociado, verificá ruta, branch, `HEAD`, `git status --short` limpio y ausencia de merge/rebase/cherry-pick en curso. Leé su handoff vigente y la Issue referida para confirmar que no declara commits, cambios o pendientes no transferidos. Si hay cambios, operación Git inconclusa o pendientes no transferidos, no cierres ese cedente: informá bloqueo y conservalo `inactivo`.
4. Actualizá el handoff del WT que se cierra con resultado, commits o integración, validaciones, cedentes cerrados o bloqueados y líneas afectadas. No escribas un nuevo handoff obligatorio para el cedente salvo que {{APROBADOR}} lo pida o haya información relevante que sólo pueda quedar allí.
5. Cambiá el estado del WT actual a `cerrado` y cambiá a `cerrado` los cedentes asociados que pasaron las verificaciones, con motivo `línea cerrada por receptor WTxx`. No reasignes filas ni reutilices IDs. Avisá a los WT dependientes.
6. Si tenés capacidad real de interfaz, renombrá el chat saliente como `XX_[WT]_[VERSIÓN]_[NOMBRE]` y archivalo en la misma ejecución. No conviertas el archivado en un segundo paso manual para preservar visibilidad del resumen: {{APROBADOR}} revisa el resumen desde archivados si lo necesita. Sólo entregá acción manual si la interfaz no permite archivar o si el archivado falla explícitamente, indicando el nombre exacto esperado. `worktree-close` no usa ni inventa prefijos `CL_...`: el estado `cerrado` vive en `OWNERS.md` y el chat archivado sigue siendo histórico `XX_...`. Informá por separado cualquier limpieza posible.

Cerrar no autoriza borrar worktree, rama, archivos o commits. La limpieza destructiva requiere otra solicitud.
