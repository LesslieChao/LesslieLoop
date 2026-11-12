---
name: worktree-create
description: Crear y registrar un worktree nuevo con worker y responsabilidad propios dentro de un proyecto ya inicializado. Usar cuando {{APROBADOR}} solicite una nueva linea de trabajo.
---

# Crear WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Verificar proyecto, raiz Git, remotos, worktrees y `OWNERS.md` personal. Confirmar base, worker y responsabilidad; no inferir una reasignacion de territorio existente. Contar filas `activo`: si ya hay cinco, no crear ni registrar otro WT hasta que {{APROBADOR}} elija uno para pausar o cerrar.
2. Elegir o validar un ID `WTxx`, título, ruta absoluta y branch únicos. La carpeta debe ser `<directorio de worktrees>/WTxx - Título`; no incluir worker, estado, handoff o chat en el título. La rama nace del commit o referencia acordados; no asumir `dev` si la base cambia el resultado.
3. Crear el worktree y la rama sin modificar ni limpiar otros WT. Ante colision, cambios fuera de scope o referencia inexistente, detenerse.
4. Agregar una fila `activo` a `OWNERS.md` y crear `WTxx/history/` y `WTxx/HANDOFF.md`. Registrar el punto de partida Git y el encargo inicial; no copiar estos archivos al producto.
5. Preparar el nombre del chat vigente como `00_[WT]_[NOMBRE]`, por ejemplo `00_WT06_Estándar mínimo del cliente`. Si existe herramienta real para renombrarlo, usarla durante el alta y verificar el resultado; si no existe o falla, informar explícitamente «pendiente manual: renombrar este chat a ...». No dejar el alta con un nombre genérico o con el texto del prompt.
6. Verificar ruta, branch y `HEAD` desde el WT nuevo. Informar el alta y esperar la eleccion de {{APROBADOR}} antes de implementar.

No reutilizar una carpeta o rama perteneciente a otro worker. No crear Issue, commit, push o PR solamente por dar de alta el WT.

Usar `worktrees/` y la convención de ramas de PROJECT. Resolver el checkout administrativo registrado aun cuando el chat esté abierto en la carpeta contenedora. Verificar el commit base antes de crear; si falla Git no agregar una fila activa. Si ya existe una creación parcial, reconciliarla con el registro sin duplicarla. El alta escribe HANDOFF y history/0001.md con el mismo texto.
