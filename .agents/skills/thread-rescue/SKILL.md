---
name: thread-rescue
description: Rescatar en Codex Desktop un WT cuyo chat activo quedó roto y fue duplicado desde la última respuesta útil.
---

# Rescatar thread duplicado

Usar cuando {{APROBADOR}} indique que un chat de Codex quedó roto, no responde o aparece con error, y existe un duplicado funcional del mismo WT, por ejemplo `00_WT04_Seguridad` y `00_WT04_Seguridad (2)`.

Antes de actuar, leer `~/.{{ARNES}}/CONTRATO_HANDOFF.md` y resolver identidad, WT y proyecto desde `PROJECT.md`, `OWNERS.md`, ruta del WT y handoff vigente. No modificar `OWNERS.md`, no crear/cerrar/reactivar WT, no hacer commits, push, PR ni merge. Esta skill sólo corrige la interfaz del chat y deja el WT listo para continuar con `$context-resume`.

1. Listar tasks/threads relacionados con el nombre base del WT. Identificar el thread roto y el thread funcional sin enviar mensajes al roto. La inferencia automática sólo es válida si hay exactamente dos candidatos: `NOMBRE` roto y `NOMBRE (2)` funcional, o equivalente inequívoco.
2. Si hay más de dos candidatos, ninguno, dos funcionales, dos rotos o cualquier duda razonable, detenerse antes de tocar la interfaz y pedir confirmación concreta. No archivar ni renombrar por aproximación.
3. Verificar que el thread funcional corresponde al mismo WT: nombre base, proyecto, handoff vigente y ruta registrada. No actualizar el handoff desde el thread roto.
4. Si el roto todavía no está archivado ni marcado, renombrarlo con marca histórica distinguible: `NOMBRE [roto archivado YYYY-MM-DD]`. Luego archivarlo con herramienta real, por ejemplo `set_thread_title` y `set_thread_archived`. Si alguna herramienta falla, informar el paso manual exacto y no simularlo.
5. Renombrar el thread funcional quitando sufijos de duplicación como ` (2)` para que quede `00_[WT]_[NOMBRE]`. Si ya está normalizado, no duplicar nombres. La operación debe ser idempotente.
6. Navegar o indicar abrir el thread funcional y continuar allí con `$context-resume` o el prompt `Continuá WTxx`. El resume verifica Git y handoff; el rescate no implementa tareas del producto.

Resultado esperado: el thread roto queda archivado y distinguible, el funcional queda visible como `00_[WT]_[NOMBRE]`, y el siguiente paso ocurre desde el thread funcional. Informar qué se renombró, qué se archivó, qué no se tocó y si quedó algún paso manual.
