---
name: context-resume
description: Abrir o reanudar un chat Codex sobre un worktree existente leyendo su handoff vigente y verificando Git. Usar al invocar $context-resume o cuando {{APROBADOR}} diga «Continuá WTxx»; presentar tareas A/B/u otro y esperar su elección.
---

# Abrir el WT sin repetir contexto

Antes de actuar, leer ~/.{{ARNES}}/CONTRATO_HANDOFF.md y resolver el proyecto por su PROJECT.md, si ya existe. Usar las plantillas de ~/.{{ARNES}}/templates/. Si falta la instalación, informar la pieza faltante. La identidad registrada prevalece sobre un remoto agregado después. Toda escritura del handoff crea una nueva versión inmutable; las comunicaciones usan el destino privado explícito de PROJECT.

1. Resolver la identidad desde PROJECT aunque el chat esté abierto en la carpeta contenedora. Consultar OWNERS, obtener la ruta absoluta del `WTxx` y recién entonces ejecutar Git. Verificar checkout administrativo, directorio común, carpeta exacta y branch con `git worktree list`, `git rev-parse`, `git status --short` y, sólo si hay cambios pertinentes, diff. Comprobar worker y estado; si es `inactivo`, no reactivarlo por inferencia.
2. Leer solamente `WTxx/HANDOFF.md` vigente en el estado personal. No leer `history/`, todos los documentos del repo ni los chats anteriores por rutina. Las instrucciones personales ya vienen cargadas. Si el handoff trae contexto SSH heredable, comprobar primero el alias SSH, shell/binario, `SSH_AUTH_SOCK` y tipo de agente registrados antes de declarar bloqueo de autenticación; en Windows distinguir fallo de PowerShell/OpenSSH o PowerShell/Windows OpenSSH de acceso disponible vía Git Bash/MSYS. Si el socket, binario o alias ya no existe o no autentica, informar el bloqueo y pedir intervención del usuario; nunca guardar claves privadas, passphrases, contenido de `.env`, ni ejecutar `ssh-add` o iniciar `ssh-agent` sin acción explícita del usuario. Si es el primer chat sin handoff, consultar `docs/CONTEXTO_INICIAL.md` del producto cuando exista y el objetivo inicial comunicado por {{APROBADOR}}.
3. Comparar ruta, branch, `HEAD`, estado limpio/sucio y archivos cambiados con el handoff. Si no coinciden, describir diferencia antes de proponer trabajo; no retroceder Git ni asumir que la versión archivada sigue vigente.
4. Normalizar el chat sucesor antes de responder: el chat actual debe llamarse `00_[WT]_[NOMBRE]`, por ejemplo `00_WT02_Prueba Claude`. Si existe herramienta real para renombrarlo, hacerlo y verificarlo. Si no existe o falla, no simularlo: indicar explícitamente «pendiente manual: renombrar este chat a ...». No dejar el chat con el texto del prompt, como `Continuá WTxx`.
5. Responder: «Listo para continuar en WTxx. Verifiqué [estado breve]. Quedaron A y B; el paso sugerido era A. ¿Seguimos con A, con B o tenés otro encargo?». Si no hay dos pendientes, indicar sólo los reales. Detenerse y esperar respuesta: «Continuá WTxx» invoca **apertura**, no autoriza a implementar A.

Si no hay capacidad para crear chats nuevos, no afirmarlo; ofrecer nombre `00_[WT]_[NOMBRE]` e instrucciones manuales. Si el chat sucesor ya existe y la interfaz permite renombrarlo, `context-resume` debe intentar renombrar **ese chat actual**. Un handoff local no reemplaza Git ni transporta cambios no commiteados a otro WT.

Esta skill es de sólo lectura respecto de `OWNERS.md`: nunca crea filas ni cambia worker, rama, responsabilidad o estado. Usar la skill `worktree-*` correspondiente para cualquier cambio de ciclo de vida.

Ante worker, ruta o rama incompatibles con OWNERS, o un WT cerrado, detener la apertura sin modificar el registro. Una diferencia posterior al handoff se informa y se espera dirección antes de implementar.
