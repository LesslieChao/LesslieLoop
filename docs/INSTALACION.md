# Instalación y uso de las plantillas

Elegir una revisión del arnés validada y conservar una copia fuera de los productos.

## Instalación

Se hace en cada PC donde trabajan Codex o Claude Code, a partir del repo del arnés ya publicado en la cuenta propia. Si ese repo todavía no existe, crearlo primero con la [publicación](PUBLICACION.md); el instalador no se ejecuta sobre un clon de LesslieLoop.

Clonar el repo del arnés en una carpeta personal, fuera de los repos de producto, y desde su raíz ejecutar con PowerShell 7 o Windows PowerShell 5.1:

```powershell
git clone https://github.com/<cuenta>/<arnés>.git
cd <arnés>
pwsh -File scripts/Instalar-Arnes.ps1
```

1. **Datos.** Lee aprobador, cuenta, email, arnés y coordinación de `instalacion.json`. Si falta o quedan marcadores sin configurar, se detiene e indica publicar primero. No pide datos, no reescribe el repo ni commitea.
2. **Identidad Git.** Configura `user.name` y `user.email` de este clon con la cuenta y el email registrados.
3. **Instalación personal.** Copia skills, plantillas, documentación y scripts según la tabla siguiente. En `AGENTS.md` y `CLAUDE.md` personales agrega o actualiza sólo un bloque delimitado con el nombre del arnés y conserva el resto. Registra la revisión instalada en `instalacion.json` de la carpeta de estado.

Después de actualizar el clon (`git pull`), volver a ejecutar el mismo comando para instalar la revisión nueva. `-Inicio <carpeta>` instala en otra carpeta personal. Para cambiar los datos registrados, ver [publicación](PUBLICACION.md#cambiar-los-datos-más-adelante).

## Preparación personal

| Origen en el arnés | Destino personal | Tratamiento |
| --- | --- | --- |
| personal/AGENTS.md | ~/.codex/AGENTS.md | Integrar las reglas con las existentes |
| personal/CLAUDE.md | ~/.claude/CLAUDE.md | Integrar las reglas con las existentes |
| .agents/skills/ (cada carpeta completa) | ~/.agents/skills/ | Instalar las diez skills de Codex |
| .claude/skills/ (cada carpeta completa) | ~/.claude/skills/ | Instalar las diez skills de Claude |
| personal/PROJECT.template.md | ~/.{{ARNES}}/templates/PROJECT.template.md | Copiar plantilla |
| personal/OWNERS.template.md | ~/.{{ARNES}}/templates/OWNERS.template.md | Copiar plantilla |
| HANDOFF.template.md | ~/.{{ARNES}}/templates/HANDOFF.template.md | Copiar plantilla |
| docs/CONTRATO_HANDOFF.md | ~/.{{ARNES}}/CONTRATO_HANDOFF.md | Copiar contrato operativo |
| docs/PRINCIPIOS_DISENO.md | ~/.{{ARNES}}/PRINCIPIOS_DISENO.md | Copiar límites y criterios del arnés |
| docs/CRITERIOS_ENTREGA_PRODUCTO.md | ~/.{{ARNES}}/CRITERIOS_ENTREGA_PRODUCTO.md | Copiar criterios privados |
| docs/INSTALACION.md | ~/.{{ARNES}}/INSTALACION.md | Copiar esta guía |
| scripts/Preparar-Proyecto.ps1 | ~/.{{ARNES}}/scripts/Preparar-Proyecto.ps1 | Copiar bootstrap determinista |
| scripts/Generar-CodeGraph.ps1 | ~/.{{ARNES}}/scripts/Generar-CodeGraph.ps1 | Copiar generador de mapa compacto |
| scripts/Verificar-Identidad-Git.ps1 | ~/.{{ARNES}}/scripts/Verificar-Identidad-Git.ps1 | Copiar guard de identidad Git |
| scripts/Iniciar-Sin-Deteccion-De-Agente.ps1 | ~/.{{ARNES}}/scripts/Iniciar-Sin-Deteccion-De-Agente.ps1 | Copiar wrapper para dev servers Next sin detección de agente |
| scripts/Verificar-Artefactos-Agente-Next.ps1 | ~/.{{ARNES}}/scripts/Verificar-Artefactos-Agente-Next.ps1 | Copiar guard contra artefactos Next generados por agente |

La carpeta personal es la del equipo donde trabaja el agente. Las ubicaciones de skills se corresponden con la documentación de [Codex](https://learn.chatgpt.com/docs/build-skills) y [Claude Code](https://code.claude.com/docs/en/skills). Verificar que ambos clientes detecten las skills; cerrar y abrir una sesión si la lista no se actualiza.

Para adoptar otra revisión, comparar primero las reglas existentes y el perfil particular de PROJECT. Actualizar skills, contrato y plantillas como un conjunto, y registrar el SHA adoptado en PROJECT. Los handoffs anteriores conservan su contenido. No usar enlaces a una rama cambiante si el proyecto necesita conservar una revisión fija.

## Alta de proyecto

En Codex y Claude crear un proyecto asociado a una carpeta contenedora vacía. No clonar a mano ni seleccionar un WT como proyecto. El primer thread invoca project-init con remoto, base, rama, WT, título, worker y objetivo; la skill usa el script instalado para crear `repo/` y `worktrees/WTxx - Título/`, genera CodeGraph inicial fuera del producto, lee sólo su resumen, nombra o solicita nombrar el chat como `00_WTxx_Título` y hace sólo una lectura inicial liviana del producto.

Si algún dato que cambia Git falta, project-init lo presenta como decisión pendiente antes de escribir. El repositorio de coordinación puede quedar pendiente; no bloquea un primer WT sin cruces, pero debe existir antes de una transferencia o dependencia entre WT.

## Producto nuevo

Desde la raíz del arnés, con PowerShell 7:

```powershell
pwsh -File scripts/Preparar-Plantilla.ps1 -Tipo producto -Destino ../nuevo-producto
```

Este comando se usa para preparar el contenido inicial que luego se publica en un repositorio con commit base. No reemplaza project-init ni crea la carpeta contenedora operativa. El destino debe estar vacío o no existir; copia sólo plantilla-proyecto, incluidos los archivos ocultos.

La plantilla general no inventa variables de entorno, una licencia, dependencias ni un pipeline de pruebas. Incorporar .env.example cuando existan variables, CI cuando haya comandos ejecutables y la licencia cuando su titular haya elegido los términos.

Inicializar Git cuando corresponda, crear el commit base y luego registrar el proyecto con project-init. Un WT adicional requiere un commit base real. Los datos aún desconocidos se mantienen como pendientes y no se presentan como verificados.

## Producto existente

No ejecutar la copia sobre el checkout existente. Generar un candidato vacío, comparar sus archivos y portar sólo las mejoras necesarias, conservando la documentación y configuración actuales. Registrar el proyecto con project-init no modifica su código.

## Coordinación privada

```powershell
pwsh -File scripts/Preparar-Plantilla.ps1 -Tipo coordinacion -Destino ../nueva-coordinacion
```

Elegir el remoto privado por separado. Publicar las plantillas en su rama predeterminada, habilitar Issues y crear las etiquetas siguiendo el README generado. Registrar el destino exacto en PROJECT; las comunicaciones no deben depender del directorio desde el que se ejecuta GitHub CLI.

## Registro operativo

project-init copia las plantillas personales a projects/identidad/PROJECT.md y OWNERS.md. El primer WT se registra sólo cuando existen su carpeta y rama, y recibe HANDOFF.md más history/0001.md.

No reemplazar OWNERS ni mover la identidad cuando aparezca origin. Actualizar el remoto en PROJECT y conservar el registro original. Al abrir otro chat del mismo WT, context-resume sólo verifica y presenta pendientes.

Las exclusiones personales de carpetas auxiliares se configuran mediante Git local (info/exclude o core.excludesFile); no agregar nombres de agentes a gitignore del producto.

CodeGraph se genera bajo `projects/identidad/codegraph/WTxx/` con `Generar-CodeGraph.ps1`. Sirve para leer primero un resumen compacto y abrir después sólo archivos puntuales; no se versiona ni se copia al repo del producto.

La identidad Git autorizada se registra en PROJECT. Antes de crear o publicar commits ejecutar `Verificar-Identidad-Git.ps1` con el `user.name` y `user.email` exactos esperados; no construir direcciones noreply por inferencia.

En proyectos Next.js, cuando un agente necesite levantar el dev server debe hacerlo con `Iniciar-Sin-Deteccion-De-Agente.ps1`, por ejemplo `pwsh -File ~/.{{ARNES}}/scripts/Iniciar-Sin-Deteccion-De-Agente.ps1 npm run dev`. Antes de commit o push, ejecutar `Verificar-Artefactos-Agente-Next.ps1` desde el repo del producto para bloquear `AGENTS.md`/`CLAUDE.md` generados por Next y cambios espurios de `next-env.d.ts` hacia `.next/dev/types`.

## Comprobación del paquete

Ejecutar `python scripts/verificar_plantillas.py` con Python 3.11+ y las dependencias de `scripts/requirements.txt` instaladas en el entorno de validación (`python -m pip install -r scripts/requirements.txt`). Requiere Git y PowerShell 7. Prueba las copias, enlaces, frontmatter y reglas de ignore en repositorios temporales; no modifica la configuración personal ni usa GitHub.
