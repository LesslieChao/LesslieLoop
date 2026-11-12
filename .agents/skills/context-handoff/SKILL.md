---
name: context-handoff
description: Cerrar el contexto de un chat Codex en un punto estable y dejar una nueva versión del handoff del mismo worktree fuera del repo del producto. Usar cuando {{APROBADOR}} invoque $context-handoff.
---

# Cerrar contexto del WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Terminar sólo la operación inmediata segura; no empezar otra fase. Verificar `git rev-parse --show-toplevel`, `git worktree list`, remoto `origin`, branch, `HEAD`, `git status --short` y diff pertinente. Identificar WT y dueño en `~/.{{ARNES}}/projects/<identidad>/OWNERS.md`. Si faltan la identidad o la fila del WT, detenerse y pedir el dato en vez de adivinarlo.
2. Ejecutar únicamente la validación mínima apropiada y registrar resultado. Si hay cambios ajenos al scope, conflictos o estado incoherente, informar y detenerse; no descartar ni hacer stash de cambios.
3. En `~/.{{ARNES}}/projects/<identidad>/WTxx/` redactar un `HANDOFF.md` breve: objetivo; estado; cambios y decisiones vigentes; validaciones; pendientes A/B y sugerencia; bloqueos; Issues/PR relevantes; ruta exacta del WT, branch, `HEAD`, estado Git y archivos modificados. Si esta sesión usó SSH funcionalmente, registrar contexto SSH heredable mínimo: alias SSH, shell/binario que funcionó, si había `SSH_AUTH_SOCK` usable, tipo de agente observado (`PowerShell/OpenSSH` o `Git Bash/MSYS`) y comando seguro de verificación. Si no se usó SSH, no agregar sección SSH ni diagnosticar agentes sólo por rotar. No copiar el transcript, secretos ni reglas personales; nunca guardar claves privadas, passphrases, contenido de `.env`, ni ejecutar `ssh-add` o iniciar `ssh-agent` sin acción explícita del usuario.
4. Determinar versión siguiente del WT a partir de `history/`; guardar la nueva versión también en `history/NNNN.md`, conservar inmutables las previas y dejar `HANDOFF.md` como copia vigente. Comprobar que ambas copias coincidan. Usar esa versión con al menos dos dígitos al nombrar el chat histórico.
5. Para rotación conservar el **mismo WT, branch y worker**. Los cambios coherentes pueden permanecer sin commit. No crear commit, push, PR, Issue o merge sólo por rotar.
6. Renombrar el chat `00_[WT]_[NOMBRE]` a `XX_[WT]_[VERSIÓN]_[NOMBRE]`, archivarlo y abrir `00_[WT]_[NOMBRE]` dentro del mismo proyecto contenedor sólo si hay capacidad real de interfaz. En caso contrario, comunicar explícitamente lo pendiente y entregar ambos nombres, la acción de archivo y el prompt `Continuá WTxx`.
7. Si el chat sucesor fue creado o solicitado correctamente, terminar el cierre sin esperar, leer ni monitorear la respuesta del sucesor. No llamar herramientas de espera o lectura sobre el chat sucesor salvo pedido explícito de {{APROBADOR}}, o salvo estado técnico ambiguo que impida saber si el chat existe.
8. Informar a {{APROBADOR}} estado, validaciones, cambios no commiteados, Issues que lo afectan, nombre histórico esperado, nombre sucesor esperado, prompt sucesor, identificador devuelto por la herramienta de creación si existe y pasos manuales. Si se creó un Issue por una dependencia real, adjuntar enlace y destinatario. No ejecutar el próximo paso.

No modificar `OWNERS.md`. Cambiar de worker es una operación distinta administrada por `$worktree-transfer`; la integración real sí requiere aprobación de {{APROBADOR}} para el merge a `dev` y también para promover `dev` a `main`.
