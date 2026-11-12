# Principios de diseño del arnés

`{{ARNES}}` es una capa pequeña para que una persona coordine pocas líneas de trabajo con Codex y Claude. No es un sistema de gestión de agentes ni debe necesitar un operador propio.

1. **Concurrencia limitada y humana.** Un proyecto admite como máximo cinco WT en estado `activo`. Lo habitual es uno a tres; tres o cuatro sólo cuando el trabajo lo justifica. Antes de crear o reactivar un WT se cuenta `OWNERS.md`; al alcanzar el límite se pausa o cierra otra línea, o se rechaza el alta.
2. **Harness determinista.** Git, ramas, worktrees, archivos de estado, validaciones y comandos resuelven la coordinación comprobable. La inteligencia se usa para trabajar; los mecanismos deterministas, para coordinar.
3. **Simplicidad demostrable.** No se agregan orquestadores LLM, agentes de PM, buses de mensajes, dashboards paralelos, knowledge graphs, locking multiwriter, auditores permanentes ni nuevos registros sin una necesidad observada y una reducción neta de complejidad.
4. **Un WT, un owner escritor.** Cada WT tiene un único worker con escritura. Un relevo es explícito y el receptor trabaja en su propio WT; no se comparte una carpeta ni se reasigna silenciosamente una fila.
5. **HANDOFF es un checkpoint.** Resume sólo lo necesario para retomar, pausar, transferir, rotar el chat o cerrar una etapa. No es un chat, mailbox, bitácora narrativa ni bus de mensajes.
6. **Git es la fuente de verdad del trabajo.** Commits, ramas, diffs, PR y archivos reales prevalecen sobre relatos o estados derivados. El arnés no duplica información que Git permite reconstruir de manera fiable.
7. **Estado persistente mínimo.** `PROJECT` guarda identidad y reglas particulares; `OWNERS`, ownership actual; `HANDOFF`, estado inmediato; `history`, checkpoints anteriores que no se cargan por defecto. `codegraph` es evidencia derivada opcional para ahorrar contexto, no un ledger. Las Issues privadas se reservan para coordinación que realmente cruza WT o proyectos; son obligatorias para transferencias y dependencias, y referencian Git y los handoffs sin duplicarlos.
8. **Validar, no confiar.** Abrir, reanudar o transferir exige comprobar mecánicamente repositorio, ruta, worktree, rama y estado Git. Una instrucción textual no reemplaza un check disponible.

Toda propuesta de ampliar el arnés debe indicar qué problema observado resuelve, qué estado agrega y qué mecanismo existente puede eliminar. Si no reduce el costo total de coordinación, no se incorpora.
