---
name: worktree-pause
description: Pausar un worktree activo conservando su carpeta, rama y trabajo, y actualizar su ownership personal. Usar cuando {{APROBADOR}} pida detener temporalmente una linea.
---

# Pausar WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Verificar WT, worker, ruta, branch, `HEAD`, status y fila activa en `OWNERS.md`.
2. Actualizar el handoff vigente con estado Git, cambios sin commit, validaciones, pendientes y motivo de pausa. No crear commits solamente para pausar.
3. Cambiar exclusivamente el estado de la fila a `inactivo`. Conservar worker, ruta, branch y responsabilidad.
4. Si existe capacidad de interfaz, renombrar el chat como `IN_[WT]_[NOMBRE]` y archivarlo; si no, entregar la accion manual. No dejar un WT inactivo con chat `00_...` ni marcar el WT como cerrado.
5. Informar como reactivarlo y cualquier dependencia que siga bloqueando otras lineas.

No borrar carpeta o rama, descartar cambios, hacer stash, integrar a `dev` ni crear otro WT por inferencia.
