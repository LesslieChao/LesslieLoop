---
name: worktree-transfer
description: Transfiere trabajo entre Claude y Codex mediante commits verificables y worktrees separados, sin exigir PR ni merge a dev.
argument-hint: "[WT saliente] [WT receptor] [commits]"
disable-model-invocation: true
---

# Transferir entre workers

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

Precisar si es una cesión total o una entrega parcial de cambios. La operación tiene dos etapas, ejecutadas por sus respectivos workers.

Antes de ejecutar cualquier etapa, validá que el WT solicitado como saliente coincide con el WT/thread actual. Resolvé el WT actual desde el chat, `OWNERS.md`, ruta del WT y handoff vigente. Si el pedido nombra otro WT o no podés verificar con confianza que este thread sea el WT saliente solicitado, no modifiques `OWNERS.md`, `HANDOFF.md`, Issues, títulos ni archivo de chats. Si existe un único thread correcto identificable para el WT solicitado, redirigí allí el encargo y terminá informando que este thread era incorrecto; la transferencia debe ejecutarse desde cero en el thread correcto. Si no hay un único thread correcto inequívoco, bloqueá y respondé que no podés transferir desde este chat equivocado, indicando que {{APROBADOR}} debe abrir o reanudar el WT correcto. No pidas autorización para hacerlo desde el thread equivocado.

## Saliente

1. Verificar tu propio WT, diff, validaciones e identidad Git autorizada desde PROJECT con `~/.{{ARNES}}/scripts/Verificar-Identidad-Git.ps1` antes de crear commits. En proyectos Next.js, levantá dev servers con `~/.{{ARNES}}/scripts/Iniciar-Sin-Deteccion-De-Agente.ps1` y ejecutá también `~/.{{ARNES}}/scripts/Verificar-Artefactos-Agente-Next.ps1` antes de commitear o transferir. Dejar los cambios transferibles en commits coherentes y registrar SHA en orden, base y dependencias; excluir archivos operativos. Verificar los SHA resultantes o el rango propio a publicar con el mismo script antes de transferirlos. Si el receptor usa otro clon, poner los commits a su alcance mediante la rama y el push autorizados sólo después de validar ese rango propio, no toda la historia.
2. Registrá el objetivo, pruebas y pendientes en un nuevo handoff. Prepará o actualizá la Issue en el repositorio privado configurado y firmá con worker/WT reales. Usala como coordinación y acuse: referenciá commits y handoffs sin duplicar diffs ni el checkpoint. Dejá en la Issue y en la respuesta final un bloque **Prompt para el receptor** listo para copiar, con enlace a la Issue, WT receptor esperado, si debe crear o reactivar WT, base/rama sugerida, commits en orden, validaciones esperadas y límites explícitos como no tocar WT ajenos ni hacer push, PR o merge salvo que {{APROBADOR}} lo haya pedido. Ese enlace a la Issue privada es sólo para coordinación interna: no lo copies al cuerpo, título, commits, changelog ni documentación del producto.
3. Formateá el **Prompt para el receptor** según destino: para Codex usá `$worktree-transfer` e instrucciones en estilo Codex; para Claude usá `/worktree-transfer` e instrucciones en estilo Claude Code. Incluí `Destino: Codex` o `Destino: Claude` en el bloque para evitar ambigüedad.
4. En cesión total, después de entregar en el chat actual el enlace a la Issue, estado de la cesión, **Prompt para el receptor** y acciones manuales pendientes, detenete y esperá confirmación humana de {{APROBADOR}} (`listo`, `completado`, `archivar` o equivalente). No renombres ni archives el thread saliente antes de esa confirmación. Si {{APROBADOR}} interrumpe antes del archivado, el estado debe seguir recuperable desde la Issue y el handoff.
5. Sólo después de esa confirmación humana, si cedés toda la responsabilidad y dejás de trabajar, marcá tu fila inactiva y dejá en tu responsabilidad la marca normalizada `cedida total a WTxx; issue #n`, donde `WTxx` es el receptor y `#n` la Issue de transferencia. Cerrá el chat operativo saliente como `IN_[WT]_[NOMBRE]`: renombralo y archivalo si la interfaz lo permite; si no, dejá esa acción manual explícita. No dejes un WT inactivo con chat `00_...`. Una entrega parcial conserva su estado y su chat vigente y no usa esa marca. La entrega queda preparada hasta recibir el acuse; no afirmes que el otro WT ya incorporó cambios.

## Receptor

1. Verificar que los commits pertenecen al mismo producto; este procedimiento no une historias independientes del original y su extracción sanitizada.
2. Buscar primero un WT propio inactivo de una cesión anterior. Si existe, verificar rama, HEAD, divergencias y commits ya recibidos, y reactivarlo mediante /worktree-reactivate; si no existe, crear uno mediante /worktree-create. Confirmar estado limpio y sin operaciones Git inconclusas, base correcta y disponibilidad de todos los commits.
3. Verificar identidad Git autorizada desde PROJECT con `~/.{{ARNES}}/scripts/Verificar-Identidad-Git.ps1` antes de incorporar. Incorporar normalmente mediante cherry-pick en el orden indicado; usar una rama desde el commit si {{APROBADOR}} eligió esa continuación. Verificar los SHA recibidos o el rango propio resultante antes de acusar o publicar. Ante conflictos, informar el estado y detenerse sin descartar cambios.
4. Revisar el resultado y ejecutar validaciones. Registrar SHA de origen → SHA recibido y el resultado en su handoff; confirmar la recepción en la Issue. Mantener la fila receptora activa con alcance explícito y comunicar cualquier bloqueo.

Cada worker modifica y prueba sólo su propia carpeta; el saliente no ejecuta la etapa receptora en nombre del otro. Los handoffs de ambos documentan su etapa y el acuse. PR y merge a dev corresponden a integración real, no al transporte obligatorio de un relevo.
