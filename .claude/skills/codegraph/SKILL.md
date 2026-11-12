---
name: codegraph
description: Genera o actualiza un mapa compacto de un worktree fuera del producto para reducir lectura de contexto.
argument-hint: "[WTxx] [alcance]"
disable-model-invocation: true
---

# Generar CodeGraph

Usar cuando {{APROBADOR}} pida codegraph, mapa del repo, reducir tokens, ubicar impacto o entender arquitectura sin leer carpetas completas. CodeGraph es evidencia privada derivada: Git y los archivos reales siguen siendo la fuente de verdad.

Antes de actuar, leer `~/.{{ARNES}}/CONTRATO_HANDOFF.md` y resolver el proyecto por su `PROJECT.md`. Si falta la instalación o `~/.{{ARNES}}/scripts/Generar-CodeGraph.ps1`, informar la pieza faltante. No escribir nada dentro del repo del producto.

1. Resolver `WTxx` desde `OWNERS.md`, obtener su ruta absoluta y verificar Git: carpeta, branch, `HEAD`, estado corto y directorio común. Si el WT está cerrado o pertenece a otro worker, detenerse.
2. Ejecutar `~/.{{ARNES}}/scripts/Generar-CodeGraph.ps1` con `-WTPath <ruta WT>`, `-OutputRoot ~/.{{ARNES}}/projects/<identidad>/codegraph/<WTxx>` y `-WT <WTxx>`. Ajustar límites sólo si el resultado queda incompleto para el encargo.
3. Leer `resumen.md` generado, no `graph.json` completo por rutina. Informar ruta, branch, `HEAD`, si Git estaba limpio o sucio, cantidad de archivos/edges y las señales principales para ahorrar contexto.
4. Para continuar el trabajo, abrir sólo los archivos puntuales que el resumen indique. No convertir CodeGraph en handoff, mailbox ni documentación del producto.

Durante `project-init`, generar un CodeGraph inicial por defecto después de crear/verificar el WT y antes de leer documentación del producto. En `context-handoff`, registrar como máximo que existe un CodeGraph vigente para cierto `HEAD` y su ruta privada.
