---
name: worktree-pause
description: Pausa un worktree activo conservando carpeta, rama y trabajo, y actualiza su ownership personal.
argument-hint: "[WTxx]"
disable-model-invocation: true
---

# Pausar WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Verificá WT, worker, ruta, branch, `HEAD`, status y fila activa.
2. Actualizá el handoff con estado Git, cambios sin commit, validaciones, pendientes y motivo. No commitees sólo para pausar.
3. Cambiá exclusivamente el estado a `inactivo`; conservá worker, ruta, branch y responsabilidad.
4. Si podés operar la interfaz, usá `IN_[WT]_[NOMBRE]` y archivalo; si no, entregá la acción manual. No dejes un WT inactivo con chat `00_...` ni marques la línea como cerrada.
5. Informá cómo reactivarla y dependencias pendientes.

No borres, descartes, hagas stash, integres a `dev` ni crees otro WT por inferencia.
