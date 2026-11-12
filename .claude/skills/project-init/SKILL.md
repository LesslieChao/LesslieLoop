---
name: project-init
description: Prepara una carpeta contenedora vacia, registra el proyecto y da de alta su primer worktree sin copiar coordinacion al producto.
argument-hint: "[identidad] [WTxx] [responsabilidad]"
disable-model-invocation: true
---

# Iniciar proyecto operativo

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Tratá la carpeta abierta como contenedora del proyecto, no como checkout. Para un alta nueva debe existir y estar vacía. Confirmá remoto o fuente, base, rama nueva, `WTxx`, título, worker y responsabilidad; no inventes ninguno que cambie el resultado.
2. Buscá un PROJECT existente por carpeta contenedora, checkout administrativo, directorio Git común o remoto. Si corresponde al mismo proyecto, reconciliá el alta sin sobrescribir OWNERS ni handoffs; si corresponde a otro, detenete. Para una identidad nueva usá owner/repo o local/nombre acordado y conservala aunque cambie origin.
3. Ejecutá `~/.{{ARNES}}/scripts/Preparar-Proyecto.ps1` con los datos confirmados. Este comando crea `repo/`, `worktrees/WTxx - Título/` y la rama desde la base sin upstream automático; el push futuro debe ser explícito. Si falta o falla, no improvises otra disposición ni registres un WT activo; informá el estado parcial exacto.
4. Verificá desde el WT creado `git worktree list`, remoto, branch, `HEAD`, limpieza y directorio Git común. Comprobá que el nombre sea exactamente `WTxx - Título` y que `repo/` no se use como territorio de implementación.
5. Prepará el nombre del chat vigente como `00_[WT]_[NOMBRE]`, por ejemplo `00_WT01_Revisión inicial`. Si existe capacidad real de interfaz para renombrarlo, hacelo y verificalo; si no, informá el nombre exacto como acción manual pendiente. La convención aplica también al primer chat, no sólo a sucesores.
6. Copiá PROJECT.template.md y OWNERS.template.md al directorio `projects/identidad/`. Registrá carpeta contenedora, `repo/`, `worktrees/`, Git, perfil, validaciones, revisión del arnés, coordinación privada e identidad Git autorizada para commits (`user.name` y `user.email` exactos). No infieras ni construyas direcciones `users.noreply.github.com`; si el dato exacto falta, dejalo pendiente y advertí que no se puede commitear hasta completarlo.
7. Generá CodeGraph inicial con `~/.{{ARNES}}/scripts/Generar-CodeGraph.ps1` en `projects/identidad/codegraph/WTxx/` y leé primero sólo `resumen.md`. Si falta el script, continuá el alta registrando esa falta como pendiente; no lo reemplaces leyendo carpetas completas.
8. Agregá el primer WT con ID, nombre, worker, ruta absoluta, rama y responsabilidad confirmada. Creá el handoff inicial y `history/0001.md` con idéntico contenido, incluyendo la ruta del CodeGraph y el `HEAD` cubierto cuando exista. Comprobá que ningún archivo operativo entró al producto.
9. Mantené liviana la lectura inicial del producto: usá el resumen de CodeGraph, README o documento de entrada, manifiestos de comandos, configuración de validaciones e instrucciones públicas esenciales. No leas especificaciones completas, historiales, matrices ni carpetas de documentación por rutina; consultalas sólo cuando el objetivo inicial lo exija de forma concreta. Registrá como pendiente lo no leído que pueda afectar los primeros pasos.
10. Informá el alta y presentá los primeros pasos A/B/u otro. Esperá la elección de {{APROBADOR}} antes de implementar. No dupliques carpetas, filas o ramas al reintentar una inicialización parcial.

Si el origen es un producto existente, clonalo y conservá sus documentos. Si el encargo es crear contenido desde cero, prepará primero un repo Git con commit base real y copiá sólo plantilla-proyecto; no inventes tecnología, licencia, comandos ni resultados.
