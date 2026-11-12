# LesslieLoop

Arnés personal de Nahuel Hernán Rodríguez para Codex y Claude Code. Copyright © 2026 Nahuel Hernán Rodríguez, publicado con licencia MIT: ver [LICENSE](LICENSE), [NOTICE](NOTICE) y [PROCEDENCIA](PROVENANCE.md).

Este repositorio es una instantánea fechada del arnés desarrollado desde el 15/09/2026. El contenido que sigue es el README original del arnés.

---

## {{ARNES}}

Este repositorio privado es la **fuente del arnés personal** de Codex y Claude Code. `plantilla-proyecto/` contiene solamente los archivos compartibles con un proyecto nuevo. {{APROBADOR}} elige el trabajo de cada worker; no hay un orquestador LLM. El arnés coordina pocas líneas mediante mecanismos deterministas y no debe convertirse en otro sistema que administrar.

## Separación

| Ubicación | Qué guarda |
| --- | --- |
| `personal/`, `.agents/skills/`, `.claude/skills/` de este repo | Reglas y skills personales que se instalan fuera de los proyectos. |
| `~/.{{ARNES}}/projects/<identidad>/` | PROJECT, OWNERS y handoffs locales por WT, incluidas sus versiones anteriores. |
| `~/.{{ARNES}}/projects/<identidad>/codegraph/` | Mapas compactos privados del repo para reducir lectura de contexto. |
| Repositorio privado creado desde `plantilla-coordinacion/` | Issues sólo para coordinación que realmente cruza WT o proyectos. |
| Repositorio del producto | Código y decisiones del producto, sin skills, handoffs ni reglas personales. |
| WT del producto | Estado real de archivos y branch de cada línea funcional. |
| Chat | Contexto transitorio de un worker. |

**No uses «Use this template» sobre este repositorio completo:** copiaría también el arnés personal. Para un proyecto nuevo, copiá exclusivamente el contenido de `plantilla-proyecto/` a un repo propio. Si el repo de producto ya existe, incorporá únicamente los documentos del proyecto que falten. En cada carpeta de WT, abrí Codex o Claude Code con su configuración personal instalada.

## Publicación (una vez por cuenta)

Desde un clon de LesslieLoop ejecutá `pwsh -File scripts/Publicar-Arnes.ps1`. Pide quién aprueba, la cuenta y el email de GitHub, el nombre del arnés y el repo de coordinación; arma una copia limpia sin historial, crea `<cuenta>/<arnés>` privado con `main` y `dev` en un único commit y, si falta, el repo de coordinación. Ver [publicación](docs/PUBLICACION.md).

## Instalación (una vez por equipo)

1. Cloná `<cuenta>/<arnés>` en una carpeta personal, fuera de los repos de producto.
2. Ejecutá `pwsh -File scripts/Instalar-Arnes.ps1` desde su raíz. Lee los datos ya publicados en `instalacion.json`, no pide nada ni modifica el repo, e instala reglas, skills, plantillas, documentación y scripts como conjunto. Ver [instalación](docs/INSTALACION.md).
3. Al crear un proyecto, asociá Codex y Claude a una carpeta contenedora vacía. project-init crea `repo/`, `worktrees/WT01 - Título/`, PROJECT y OWNERS. La identidad owner/repo o local/nombre persiste aunque cambie el remoto.

`plantilla-proyecto/` inicia un producto compartible y exige documentación sanitizada junto con cada PR. `plantilla-coordinacion/` inicia, por separado, el repositorio privado de comunicación. Nunca copiar una plantilla sobre el destino equivocado.

Ambos paquetes incluyen su propio gitignore. Usá `scripts/Preparar-Plantilla.ps1` para copiarlos completos a destinos vacíos y `scripts/verificar_plantillas.py` para comprobar el conjunto. El [procedimiento de instalación](docs/INSTALACION.md) también cubre proyectos existentes y actualizaciones.

Los [criterios de entrega de producto](docs/CRITERIOS_ENTREGA_PRODUCTO.md) se comprueban en el ámbito privado. La plantilla del producto utiliza lenguaje de contribución habitual y conserva la documentación técnica necesaria; no incluye el checklist del proceso de sanitización.

Estas ubicaciones se refieren al equipo donde corre Codex/Claude Code. Si trabajan en equipos distintos, hay que copiar/sincronizar el estado personal antes de reanudar un WT: los handoffs locales no aparecen automáticamente en el otro equipo.

## Uso diario

Un proyecto puede tener como máximo cinco WT activos; la operación normal apunta a uno–tres y puede llegar a tres–cuatro cuando el trabajo lo justifique. Antes de crear o reactivar se comprueba el conteo en `OWNERS.md`.

- **Abrir primer chat del proyecto:** desde la carpeta contenedora usá `$project-init Iniciá WT01 - Título para owner/repo...` en Codex o `/project-init ...` en Claude. Incluí worker, base, rama y objetivo; el worker prepara Git, genera CodeGraph inicial privado, lee sólo su resumen, deja el chat como `00_WT01_Título` cuando pueda, propone pasos A/B/u otro y espera tu elección. La frase completa está en [inicio de sesiones](docs/Plantilla_Inicio_Sesion.md).
- **Rotar contexto:** invocá `$context-handoff` en Codex o `/context-handoff` en Claude Code. Guarda una nueva versión del estado operativo del mismo WT; no exige commit ni PR.
- **Abrir chat sucesor:** creá el chat dentro del mismo proyecto contenedor y decí `Continuá WT01`. `$context-resume` o `/context-resume` resuelve la carpeta registrada, verifica Git y el handoff, normaliza el nombre del chat a `00_WT01_Nombre` si tiene herramienta real para hacerlo, informa A/B/u otro y espera tu respuesta.
- **Crear o cambiar WT:** usá `project-init` una vez por proyecto y las operaciones `worktree-create`, `worktree-pause`, `worktree-reactivate`, `worktree-transfer` y `worktree-close`. Los WT permanentes de ambos clientes viven juntos en `worktrees/` y usan `WTxx - Título`; sólo estas operaciones modifican OWNERS. `worktree-create` debe dejar el task como `00_WTxx_Título` cuando tenga herramienta real para renombrarlo.
- **Reducir lectura de contexto:** invocá `$codegraph WTxx` o `/codegraph WTxx` cuando quieras un mapa compacto del WT antes de abrir documentación o carpetas completas. El output vive en el estado privado y no entra al producto.
- **Cruce de ownership:** las transferencias y dependencias entre WT se coordinan mediante una Issue privada firmada. La Issue referencia la evidencia; Git conserva commits y diffs, y cada handoff conserva el checkpoint de su WT. Una transferencia no exige PR ni merge a `dev` y nunca comparte cambios sin commit. Si una transferencia total deja inactivo al saliente, su chat deja de ser `00_...` y pasa a `IN_...`.
- **Rescatar un chat roto de Codex:** usá `$thread-rescue WTxx` cuando el chat activo quedó roto y Codex generó un duplicado como `00_WTxx_Nombre (2)`. El flujo archiva el roto con marca `[roto archivado YYYY-MM-DD]`, normaliza el funcional como `00_WTxx_Nombre` y después continúa con `$context-resume`. No modifica OWNERS ni crea/cierra WT.
- **Integrar código:** el worker puede preparar su PR; el merge a `dev` requiere aprobación tuya y lo ejecuta el worker. La promoción de `dev` a `main` requiere también tu aprobación expresa; sin ella ningún worker la ejecuta.

`00_[WT]_[NOMBRE]` es el chat vigente; `XX_[WT]_[VERSIÓN]_[NOMBRE]` es el histórico tras una rotación o cierre definitivo; `IN_[WT]_[NOMBRE]` identifica un WT pausado. No usar `CL_...`: el cierre vive en OWNERS/HANDOFF, no en otro prefijo de chat. Si la interfaz no permite renombrar, archivar o abrir chats, la skill te entrega los nombres, el prompt y los pasos que faltan.

Ver [principios de diseño](docs/PRINCIPIOS_DISENO.md), [contrato de handoff](docs/CONTRATO_HANDOFF.md), [CodeGraph](docs/CODEGRAPH.md) y [plantilla para el primer chat](docs/Plantilla_Inicio_Sesion.md). Los archivos `AGENTS.md`, `WORKFLOW.md` y `OWNERS.md` en la **raíz de este repo** rigen el mantenimiento de este arnés; no forman parte de `plantilla-proyecto/`.

## Mantenimiento del arnés

Los instrumentos internos de evolución del arnés viven en `maintenance/`. No se instalan como skills, no se copian a productos y no se leen durante el uso operativo normal. El registro de impacto de contexto vive en [maintenance/score/](maintenance/score/README.md): guarda eventos sanitizados, pesos brutos y scores relativos recalculables para evaluar si una mejora aumenta o reduce costo de contexto.
