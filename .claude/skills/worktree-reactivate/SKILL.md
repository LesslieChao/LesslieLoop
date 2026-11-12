---
name: worktree-reactivate
description: Reactiva un worktree inactivo después de comprobar ownership, Git y handoff; no se usa para rotar chats.
argument-hint: "[WTxx]"
disable-model-invocation: true
---

# Reactivar WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Confirmá estado `inactivo`, ruta, branch, worker y responsabilidad. Verificá `HEAD`, status y handoff. Contá filas `activo`: si ya hay cinco, no reactives hasta que {{APROBADOR}} elija otra línea para pausar o cerrar.
2. Detectá solapamientos o commits nuevos en otras líneas. Ante divergencia o carpeta ausente, pedí decisión; no reconcilies por intuición.
3. Cambiá el estado a `activo` sin alterar los demás campos ni crear otra fila.
4. Prepará `00_[WT]_[NOMBRE]`, presentá pendientes A/B/u otro y esperá la elección de {{APROBADOR}}.

Reactivar no implica merge, actualización desde `dev`, descarte ni transferencia.

Registrar la reactivación en una nueva versión del handoff con el estado Git verificado.
