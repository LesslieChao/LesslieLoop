---
name: worktree-create
description: Crea y registra un worktree nuevo con worker y responsabilidad propios dentro de un proyecto inicializado.
argument-hint: "[WTxx] [worker] [responsabilidad] [base]"
disable-model-invocation: true
---

# Crear WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Verificá proyecto, Git, worktrees y `OWNERS.md`. Confirmá base, worker y responsabilidad; no infieras una reasignación existente. Contá filas `activo`: si ya hay cinco, no crees ni registres otro WT hasta que {{APROBADOR}} elija uno para pausar o cerrar.
2. Validá ID, título, ruta y branch únicos. La carpeta debe ser `<directorio de worktrees>/WTxx - Título`; no incluyas worker, estado, handoff o chat en el título. La rama nace de la referencia acordada; no presupongas `dev`.
3. Creá worktree y rama sin modificar otros WT. Ante colisión, cambios ajenos o base inexistente, detenete.
4. Agregá una fila `activo`, creá `WTxx/history/` y `HANDOFF.md`, y registrá punto de partida y encargo fuera del producto.
5. Prepará el nombre del chat vigente como `00_[WT]_[NOMBRE]`, por ejemplo `00_WT06_Estándar mínimo del cliente`. Si existe herramienta real para renombrarlo, usala durante el alta y verificá el resultado; si no existe o falla, informá explícitamente «pendiente manual: renombrar este chat a ...». No dejes el alta con un nombre genérico o con el texto del prompt.
6. Verificá ruta, branch y `HEAD`; informá el alta y esperá la elección de {{APROBADOR}}.

No reutilices carpetas o ramas ajenas ni crees Issue, commit, push o PR sólo por el alta.

Usá `worktrees/` y la convención de ramas de PROJECT. Resolvé el checkout administrativo registrado aunque el chat esté abierto en la carpeta contenedora. Verificá el commit base antes de crear; si falla Git no agregues una fila activa. Si ya existe una creación parcial, reconciliala con el registro sin duplicarla. El alta escribe HANDOFF y history/0001.md con el mismo texto.
