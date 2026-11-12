---
name: worktree-reactivate
description: Reactivar un worktree inactivo despues de comprobar ownership, Git y handoff. Usar cuando {{APROBADOR}} pida retomar una linea pausada, no para rotar de chat.
---

# Reactivar WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Confirmar que el WT figura `inactivo` y que ruta, branch, worker y responsabilidad siguen siendo validos. Verificar `HEAD`, status y handoff vigente. Contar filas `activo`: si ya hay cinco, no reactivar hasta que {{APROBADOR}} elija otra línea para pausar o cerrar.
2. Detectar si otra linea asumio la misma responsabilidad o incorporo commits relevantes. Ante solapamiento, divergencia o carpeta ausente, informar y pedir decision; no reconciliar por intuicion.
3. Cambiar el estado a `activo` sin alterar los demas campos. No crear una fila nueva para el mismo WT.
4. Preparar el nombre `00_[WT]_[NOMBRE]` y presentar pendientes reales A/B/u otro. Esperar la eleccion de {{APROBADOR}} antes de implementar.

Reactivar no implica actualizar desde `dev`, hacer merge, descartar cambios ni transferir ownership.

Registrar la reactivación en una nueva versión del handoff con el estado Git verificado.
