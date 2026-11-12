---
name: context-handoff
description: Cerrar por contexto un chat Claude Code y versionar el handoff operativo del mismo worktree fuera del repo del producto; usar al invocar /context-handoff.
argument-hint: "[WTxx]"
disable-model-invocation: true
---

# Cerrar contexto del WT

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Terminá sólo la operación inmediata segura. Verificá raíz Git, `git worktree list`, remoto `origin`, branch, `HEAD`, `git status --short` y diff pertinente. Identificá WT, worker y carpeta en `~/.{{ARNES}}/projects/<identidad>/OWNERS.md`; si falta la identidad, pedí el dato. No comiences una fase nueva.
2. Ejecutá la validación mínima apropiada. Ante cambios fuera de scope, conflictos o un estado incoherente, informá y detenete; no descartes ni hagas stash de cambios.
3. Guardá en `~/.{{ARNES}}/projects/<identidad>/WTxx/HANDOFF.md` objetivo, estado, cambios, decisiones vigentes, validaciones, pendientes A/B, sugerencia, bloqueos, Issues/PR, ruta exacta, branch, `HEAD` y archivos modificados. Si esta sesión usó SSH funcionalmente, registrá contexto SSH heredable mínimo: alias SSH, shell/binario que funcionó, si había `SSH_AUTH_SOCK` usable, tipo de agente observado (`PowerShell/OpenSSH` o `Git Bash/MSYS`) y comando seguro de verificación. Si no se usó SSH, no agregues sección SSH ni diagnostiques agentes sólo por rotar. No incluyas transcripts, secretos ni reglas personales; nunca guardes claves privadas, passphrases, contenido de `.env`, ni ejecutes `ssh-add` o inicies `ssh-agent` sin acción explícita del usuario.
4. Asigná la siguiente versión consultando `history/`; guardá el mismo texto en `history/NNNN.md` y como `HANDOFF.md` vigente. Comprobá ambas copias; no alteres versiones viejas. Usá al menos dos dígitos en la versión del nombre del chat.
5. Conservá **el mismo WT, branch y worker**. Los cambios coherentes pueden quedar sin commit. No crees commit, push, PR, Issue o merge sólo por rotar.
6. Si podés operar la interfaz, renombrá `00_[WT]_[NOMBRE]` como `XX_[WT]_[VERSIÓN]_[NOMBRE]`, archivalo y abrí `00_[WT]_[NOMBRE]` dentro del mismo proyecto contenedor. Si no podés, avisá y entregá los nombres exactos, la acción de archivo y el prompt `Continuá WTxx`.
7. Si el chat sucesor fue creado o solicitado correctamente, terminá el cierre sin esperar, leer ni monitorear la respuesta del sucesor. No llames herramientas de espera o lectura sobre el chat sucesor salvo pedido explícito de {{APROBADOR}}, o salvo estado técnico ambiguo que impida saber si el chat existe.
8. Informá a {{APROBADOR}} estado, validaciones, cambios no commiteados, Issues que lo afectan, nombre histórico esperado, nombre sucesor esperado, prompt sucesor, identificador devuelto por la herramienta de creación si existe y pasos manuales. Si creaste un Issue por dependencia real, compartí enlace y destinatario. No empieces la próxima tarea.

No modifiques `OWNERS.md`. Un cambio de worker se administra por `/worktree-transfer`; integrar código a `dev` requiere aprobación de {{APROBADOR}} y lo ejecuta el worker. Promover `dev` a `main` también requiere aprobación expresa de {{APROBADOR}}.
