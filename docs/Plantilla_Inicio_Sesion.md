# Inicio de proyecto y sesiones

Usar sólo `plantilla-proyecto/` al crear el repo compartible. Las reglas y skills personales se instalan fuera del proyecto una vez.

## Primer chat de un WT nuevo

Crear en Codex y Claude un proyecto asociado a la carpeta contenedora vacía. Nombrar el primer thread `00_WTxx_Título` cuando la interfaz lo permita; si se inicia con otro nombre, pedir al worker que lo renombre o lo deje indicado como acción manual pendiente. Para un producto existente en GitHub, iniciar el primer thread con:

`$project-init Iniciá WT01 - [Título] para [owner/repo], con [Codex o Claude] como owner. Usá [rama] como base y creá la rama [rama nueva]. El objetivo inicial es [encargo]. Prepará repo/ y worktrees/, verificá Git, registrá el proyecto, generá CodeGraph inicial, leé sólo su resumen antes de abrir documentación del producto, dejá este chat como 00_WT01_[Título] y proponeme los primeros pasos A/B/u otro. Mantené liviana la lectura inicial: no leas especificaciones completas ni carpetas de documentación por rutina. Esperá mi elección antes de implementar.`

En Claude Code, reemplazar `$project-init` por `/project-init`. Si no se conoce la base, la rama, el remoto, el owner o el título, omitir el dato y pedir que el worker presente la decisión pendiente antes de crear carpetas.

Ejemplo:

`$project-init Iniciá WT01 - Revisión inicial para mi-org/mi-producto, con Codex como owner. Usá dev como base y creá la rama feature/revision/codex/inicial. El objetivo inicial es revisar el estado del producto sin incorporar coordinación privada al producto. Prepará repo/ y worktrees/, verificá Git, registrá el proyecto, generá CodeGraph inicial, leé sólo su resumen antes de abrir documentación del producto, dejá este chat como 00_WT01_Revisión inicial y proponeme los primeros pasos A/B/u otro. Mantené liviana la lectura inicial: no leas especificaciones completas ni carpetas de documentación por rutina. Esperá mi elección antes de implementar.`

Invocar project-init para preparar y registrar el proyecto por primera vez; usar worktree-create para otro WT dentro del mismo proyecto. En Codex los nombres se invocan con $; en Claude Code con /. El usuario no crea manualmente `repo/` ni `worktrees/`.

Si el proyecto aún no tiene WTs, el primer chat puede proponer una partición funcional, responsabilidades e interfaces; {{APROBADOR}} confirma la asignación antes de crear los WT.

## Chat sucesor del mismo WT

Codex: `Continuá WT01` (o `$context-resume WT01`). Claude Code: `Continuá WT01` (o `/context-resume WT01`).

La respuesta inicial debe indicar estado verificado, pendientes A/B y «¿seguimos con A, B u otro?». No iniciar una tarea nueva hasta que {{APROBADOR}} elija.
