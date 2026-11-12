# Contexto duradero del arnés

{{APROBADOR}} coordina directamente varios WT funcionales. Codex y Claude Code son workers. Las rotaciones de chat reducen contexto viejo sin perder la línea de trabajo.

Decisiones vigentes:

- Reglas y skills personales fuera de los repos compartidos; la plantilla sólo crea archivos específicos del producto.
- Un WT persiste a través de varios chats. El usuario decide cuándo rotar y elige la tarea al abrir el chat sucesor.
- El handoff guarda una versión breve y verificable del estado **del WT**; no guarda el transcript. Históricos fuera del repo del producto.
- Un cambio de worker crea otro WT con su propio owner. Si continúa trabajo del anterior, recibe commits identificables y los incorpora en su propia rama; no comparte carpeta ni cambios sin commit. No exige integrar a `dev`.
- Las Issues de comunicación entre workers viven fuera de los repos de producto. Se firman con worker y WT; el producto recibe sólo resultados técnicos y decisiones duraderas.
- Cada PR de un producto sanitizado actualiza la documentación pública afectada o justifica por qué no corresponde. La limpieza del producto no autoriza dejarlo sin información suficiente para usarlo, probarlo y mantenerlo.
- El propio control de sanitización pertenece al ámbito privado. Las plantillas del producto no explican ni prohíben procesos internos: describen requisitos normales de documentación, pruebas y mantenimiento.
- Un cierre definitivo del WT se registra cuando el trabajo se descarta o se integra. Informar a las líneas afectadas.
- Commit/PR son decisiones del trabajo; el merge a `dev` requiere aprobación de {{APROBADOR}} y lo ejecuta el worker. La promoción a `main` también requiere aprobación expresa de {{APROBADOR}}.
- Al abrir un chat sucesor, verificar Git y handoff, presentar pendientes y esperar «A, B u otro» antes de iniciar una fase.

No introducir memoria semántica ni grafo de decisiones en el flujo base. Si se necesita buscar decisiones antiguas, consultar las fuentes originales.
