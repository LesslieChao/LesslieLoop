---
name: context-resume
description: Abrir o reanudar el chat Claude Code de un worktree existente cuando {{APROBADOR}} diga «Continuá WTxx» o invoque /context-resume; verificar Git y presentar pendientes A/B/u otro sin implementar todavía.
argument-hint: "[WTxx]"
---

# Abrir el WT sin repetir contexto

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Resolvé la identidad desde PROJECT aunque el chat esté abierto en la carpeta contenedora. Consultá OWNERS, obtené la ruta absoluta del `WTxx` y recién entonces ejecutá Git. Verificá checkout administrativo, directorio común, carpeta y branch con `git worktree list`, `git rev-parse`, `git status --short` y diff relevante sólo si hace falta. Comprobá worker y estado; si figura `inactivo`, pedí dirección antes de reactivarlo.
2. Leé únicamente `WTxx/HANDOFF.md` vigente del estado personal. No cargues por rutina las versiones anteriores, docs completas, reglas ya inyectadas ni chats viejos. Si el handoff trae contexto SSH heredable, comprobá primero el alias SSH, shell/binario, `SSH_AUTH_SOCK` y tipo de agente registrados antes de declarar bloqueo de autenticación; en Windows distinguí fallo de PowerShell/OpenSSH o PowerShell/Windows OpenSSH de acceso disponible vía Git Bash/MSYS. Si el socket, binario o alias ya no existe o no autentica, informá el bloqueo y pedí intervención del usuario; nunca guardes claves privadas, passphrases, contenido de `.env`, ni ejecutes `ssh-add` o inicies `ssh-agent` sin acción explícita del usuario. Si es el primer chat sin handoff, consultá `docs/CONTEXTO_INICIAL.md` del producto si existe y el encargo inicial de {{APROBADOR}}.
3. Compará ruta, branch, `HEAD`, estado limpio/sucio y archivos cambiados con el handoff. Si algo difiere, describilo; no retrocedas Git ni presupongas que el handoff es más reciente.
4. Normalizá el chat sucesor antes de responder: el chat actual debe llamarse `00_[WT]_[NOMBRE]`, por ejemplo `00_WT02_Prueba Claude`. Si existe herramienta real para renombrarlo, hacelo y verificalo. Si no existe o falla, no lo simules: indicá explícitamente «pendiente manual: renombrar este chat a ...». No dejes el chat con el texto del prompt, como `Continuá WTxx`.
5. Respondé: «Listo para continuar en WTxx. Verifiqué [estado breve]. Quedaron A y B; estaba previsto A. ¿Seguimos con A, con B o tenés otro encargo?». Mencioná sólo tareas pendientes reales. **Esperá su elección** aunque el primer mensaje diga «Continuá WTxx».

Si no hay capacidad para crear chats nuevos, entregá nombre `00_[WT]_[NOMBRE]` y pasos manuales. Si el chat sucesor ya existe y la interfaz permite renombrarlo, `context-resume` debe intentar renombrar **ese chat actual**. Un handoff local no transporta cambios no commiteados a otro WT.

Esta skill sólo lee `OWNERS.md`: nunca crea filas ni cambia worker, branch, responsabilidad o estado. Usá la skill `worktree-*` correspondiente para cualquier cambio de ciclo de vida.

Ante worker, ruta o rama incompatibles con OWNERS, o un WT cerrado, detener la apertura sin modificar el registro. Una diferencia posterior al handoff se informa y se espera dirección antes de implementar.
