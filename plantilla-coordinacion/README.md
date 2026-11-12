# Coordinación privada entre workers

Repositorio privado para la coordinación persistente que realmente cruza worktrees o proyectos: dependencias, transferencias, revisiones y bloqueos entre Codex y Claude. No contiene código del producto ni sustituye sus Issues funcionales.

## Ruteo antes de crear una Issue

Antes de crear una Issue, verificar el destino:

- Incidencias del producto, coordinación entre WT del producto, dependencias de implementación o transferencias del proyecto: este repositorio privado de coordinación del proyecto.
- Incidencias del arnés, skills, reglas de WT, handoff, context-resume, worktree-transfer, thread-rescue o comportamiento de Codex/Claude como plataforma: repo `{{ARNES}}`.

Si hay duda, detenerse y preguntar antes de crear la Issue. Si una Issue fue creada en el destino incorrecto, trasladar el contenido al repo correcto y cerrar la original con enlace al reemplazo.

Toda Issue creada desde un WT debe terminar con firma normalizada:

```text
Proyecto del que viene: <nombre del proyecto>
WT: <WTxx - nombre del WT>
Plataforma: <Codex|Claude|otra>
```

## Reglas

- Identificar proyecto, WT solicitante, WT receptor y resultado esperado.
- Firmar comentarios operativos como `— Codex / WTxx` o `— Claude / WTxx`.
- Transferir código mediante commits identificables; no mediante carpetas compartidas o diffs sin commit.
- Referenciar desde aquí ramas, commits, PR o Issues del producto cuando sea necesario.
- No agregar referencias a este repositorio en commits, PR o documentación publicable del producto.
- No publicar secretos, datos operativos ni contenido innecesario del producto.
- Abrir una Issue para toda transferencia o dependencia entre WT o proyectos. No abrirla para un encargo contenido en un solo WT, una rotación de chat o un estado reconstruible desde Git y el handoff vigente.

Las decisiones técnicas duraderas y la documentación necesaria para mantener un producto pertenecen al repositorio de ese producto.

## Puesta en marcha

1. Crear este repositorio con visibilidad privada, habilitar Issues y verificar los accesos.
2. Publicar estas plantillas en la rama predeterminada para que GitHub las ofrezca al abrir una Issue.
3. Crear las etiquetas de [labels.json](labels.json); GitHub no interpreta ese archivo automáticamente. Desde esta carpeta, con GitHub CLI autenticado y el destino verificado:

```powershell
$repoCoordinacion = 'OWNER/REPO'
$visibilidad = gh repo view $repoCoordinacion --json visibility --jq .visibility
if ($LASTEXITCODE -ne 0 -or $visibilidad -ne 'PRIVATE') { throw 'Verificar el repositorio privado de destino.' }
$existentes = @(gh label list --repo $repoCoordinacion --limit 1000 --json name --jq '.[].name')
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron leer las etiquetas.' }
foreach ($etiqueta in (Get-Content -Raw labels.json | ConvertFrom-Json)) {
    if ($etiqueta.name -notin $existentes) {
        gh label create $etiqueta.name --repo $repoCoordinacion --color $etiqueta.color --description $etiqueta.description
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la etiqueta.' }
    }
}
```

4. Registrar este destino en el estado personal de cada proyecto. Al publicar desde un WT de producto, indicar siempre el repositorio de coordinación explícitamente; no depender del remoto del directorio actual.

## Ciclo de una comunicación

Una Issue reúne una necesidad hasta su resolución: solicitado → en curso → resuelto, con bloqueos cuando correspondan. Funciona como sobre de coordinación: identifica origen, receptor, referencias Git/handoff y acuse, sin copiar diffs ni narrar el checkpoint. Responder en el mismo hilo usando [el comentario operativo](plantillas/comentario.md); evitar una Issue por mensaje.

Quien abre la comunicación notifica a {{APROBADOR}} con proyecto, enlace, destinatario y efecto de bloqueo, y la cierra tras comprobar la resolución. Cada respuesta incluye firma del emisor real. Un bloqueo termina cuando se confirma el resultado; una transferencia termina con el acuse del receptor y los SHA resultantes.

Los handoffs detallados y rutas absolutas permanecen locales. En una Issue usar la referencia identidad/WT/history/versión y los commits necesarios. Si el receptor está en otra máquina, confirmar que recibió ese estado por el canal privado acordado.

## Etiquetas iniciales

Crear estas etiquetas al preparar el repositorio:

| Etiqueta | Uso |
| --- | --- |
| `tipo:encargo` | Resultado asignado a un worker. |
| `tipo:dependencia` | Cruce de ownership o contrato entre WT. |
| `tipo:transferencia` | Entrega de commits entre workers. |
| `tipo:revision` | Revisión independiente. |
| `tipo:bloqueo` | Decisión o acción externa necesaria. |

Agregar etiquetas `proyecto:<nombre>` y `worker:codex` / `worker:claude` a medida que se registren proyectos. Las plantillas no crean etiquetas automáticamente.
