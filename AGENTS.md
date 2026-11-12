# Mantenimiento del arnés

Este `AGENTS.md` se aplica a **{{ARNES}}**, no a los repos de producto creados desde `plantilla-proyecto/`.

- Mantener separadas las reglas personales (`personal/`, skills) y el contexto compartible del proyecto (`plantilla-proyecto/`). Nunca copiar el repo completo como plantilla de producto.
- Antes de preparar contenido destinado a un producto, aplicar `docs/CRITERIOS_ENTREGA_PRODUCTO.md`. Las prohibiciones y checklists sobre el proceso privado también quedan fuera de `plantilla-proyecto/`.
- Antes de cambiar una skill, comprobar el contrato en `docs/CONTRATO_HANDOFF.md` y su equivalente Codex/Claude Code.
- No requerir PR ni merge por rotar un chat, pausar un WT o transferir trabajo. Una transferencia entre WT sí usa commits identificables; la integración de código sigue `WORKFLOW.md`.
- Los WT, handoffs y nombres de chats activos pertenecen al estado personal local, fuera de los repos de producto.
- `context-handoff` y `context-resume` no modifican `OWNERS.md`; sólo las skills de ciclo de vida del proyecto y los WT pueden hacerlo.
- Mantener las instrucciones de inicio cortas: las reglas personales se cargan automáticamente y los procedimientos extensos sólo cuando se invoca una skill.
