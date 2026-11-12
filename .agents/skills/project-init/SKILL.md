---
name: project-init
description: Preparar desde una carpeta contenedora vacia, registrar un proyecto y dar de alta su primer worktree sin copiar coordinacion al producto. Usar cuando {{APROBADOR}} inicie un proyecto.
---

# Iniciar proyecto operativo

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Tratar la carpeta abierta como contenedora del proyecto, no como checkout. Para un alta nueva debe existir y estar vacía. Confirmar remoto o fuente, base, rama nueva, `WTxx`, título, worker y responsabilidad; no inventar ninguno que cambie el resultado.
2. Buscar un PROJECT existente por carpeta contenedora, checkout administrativo, directorio Git común o remoto. Si corresponde al mismo proyecto, reconciliar el alta sin sobrescribir OWNERS ni handoffs; si corresponde a otro, detenerse. Para una identidad nueva usar owner/repo o local/nombre acordado y conservarla aunque cambie origin.
3. Ejecutar `~/.{{ARNES}}/scripts/Preparar-Proyecto.ps1` con los datos confirmados. Este comando crea `repo/`, `worktrees/WTxx - Título/` y la rama desde la base sin upstream automático; el push futuro debe ser explícito. Si falta o falla, no improvisar otra disposición ni registrar un WT activo; informar el estado parcial exacto.
4. Verificar desde el WT creado `git worktree list`, remoto, branch, `HEAD`, limpieza y directorio Git común. Comprobar que el nombre es exactamente `WTxx - Título` y que `repo/` no se usará como territorio de implementación.
5. Preparar el nombre del chat vigente como `00_[WT]_[NOMBRE]`, por ejemplo `00_WT01_Revisión inicial`. Si existe capacidad real de interfaz para renombrarlo, hacerlo y verificarlo; si no, informar el nombre exacto como acción manual pendiente. La convención aplica también al primer chat, no sólo a sucesores.
6. Copiar PROJECT.template.md y OWNERS.template.md al directorio `projects/identidad/`. Registrar carpeta contenedora, `repo/`, `worktrees/`, Git, perfil, validaciones, revisión del arnés, coordinación privada e identidad Git autorizada para commits (`user.name` y `user.email` exactos). No inferir ni construir direcciones `users.noreply.github.com`; si el dato exacto falta, dejarlo pendiente y advertir que no se puede commitear hasta completarlo.
7. Generar CodeGraph inicial con `~/.{{ARNES}}/scripts/Generar-CodeGraph.ps1` en `projects/identidad/codegraph/WTxx/` y leer primero sólo `resumen.md`. Si falta el script, continuar el alta registrando esa falta como pendiente; no reemplazarlo leyendo carpetas completas.
8. Agregar el primer WT con ID, nombre, worker, ruta absoluta, rama y responsabilidad confirmada. Crear el handoff inicial y `history/0001.md` con idéntico contenido, incluyendo la ruta del CodeGraph y el `HEAD` cubierto cuando exista. Comprobar que ningún archivo operativo entró al producto.
9. Mantener liviana la lectura inicial del producto: usar el resumen de CodeGraph, README o documento de entrada, manifiestos de comandos, configuración de validaciones e instrucciones públicas esenciales. No leer especificaciones completas, historiales, matrices ni carpetas de documentación por rutina; consultarlas sólo cuando el objetivo inicial lo exija de forma concreta. Registrar como pendiente lo no leído que pueda afectar los primeros pasos.
10. Informar el alta y presentar los primeros pasos A/B/u otro. Esperar la elección de {{APROBADOR}} antes de implementar. No duplicar carpetas, filas o ramas al reintentar una inicialización parcial.

Si el origen es un producto existente, clonarlo y conservar sus documentos. Si el encargo es crear contenido desde cero, preparar primero un repo Git con commit base real y copiar sólo plantilla-proyecto; no inventar tecnología, licencia, comandos ni resultados.
