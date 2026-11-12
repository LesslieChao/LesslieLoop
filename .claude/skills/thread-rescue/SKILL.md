---
name: thread-rescue
description: Documentar o preparar el rescate de un thread Codex roto duplicado desde la última respuesta útil.
argument-hint: "[WTxx]"
disable-model-invocation: true
---

# Rescatar thread duplicado

Usar cuando {{APROBADOR}} indique que un chat de Codex quedó roto, no responde o aparece con error, y existe un duplicado funcional del mismo WT, por ejemplo `00_WT04_Seguridad` y `00_WT04_Seguridad (2)`.

Claude Code normalmente no controla la interfaz de Codex Desktop. Por eso no debe simular renombres ni archivados de Codex. Debe leer `~/.{{ARNES}}/CONTRATO_HANDOFF.md`, resolver identidad, WT y proyecto, y entregar el paquete de rescate para que Codex o {{APROBADOR}} lo ejecute.

No modificar `OWNERS.md`, no crear/cerrar/reactivar WT, no hacer commits, push, PR ni merge. Esta skill sólo identifica el caso, evita tocar el thread roto y prepara la continuación segura con `/context-resume` o con el prompt `Continuá WTxx` en el thread funcional.

1. Listar o pedir la lista de threads relacionados con el nombre base del WT. Identificar el thread roto y el funcional sin enviar mensajes al roto. La inferencia automática sólo es válida si hay exactamente dos candidatos: `NOMBRE` roto y `NOMBRE (2)` funcional, o equivalente inequívoco.
2. Si hay más de dos candidatos, ninguno, dos funcionales, dos rotos o cualquier duda razonable, detenerse antes de tocar nada y pedir confirmación concreta.
3. Verificar que el thread funcional corresponde al mismo WT: nombre base, proyecto, handoff vigente y ruta registrada. No actualizar el handoff desde el thread roto.
4. Indicar el cambio manual o para Codex: renombrar el roto como `NOMBRE [roto archivado YYYY-MM-DD]`, archivarlo, y renombrar el funcional quitando sufijos de duplicación como ` (2)` para que quede `00_[WT]_[NOMBRE]`.
5. Continuar sólo desde el thread funcional con `/context-resume` o `Continuá WTxx`. La operación debe ser idempotente: si ya está archivado o normalizado, no duplicar nombres ni reabrir threads sin confirmación.

Resultado esperado: el thread roto queda archivado y distinguible, el funcional queda visible como `00_[WT]_[NOMBRE]`, y el siguiente paso ocurre desde el thread funcional. Informar qué debe ejecutar Codex/{{APROBADOR}}, qué no se tocó y si quedó algún paso manual.
