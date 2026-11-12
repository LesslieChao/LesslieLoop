# CodeGraph

CodeGraph es un instrumento privado del arnés para reducir lectura de contexto. Genera una vista compacta de un WT: archivos, tipos, símbolos simples, dependencias detectadas, estado Git y un resumen para decidir qué abrir después.

No reemplaza a Git ni al código real. El output queda fuera del producto, en el estado personal del proyecto:

```text
~/.{{ARNES}}/projects/<identidad>/codegraph/<WTxx>/
|-- graph.json
|-- resumen.md
`-- manifest.md
```

## Uso

Desde una skill o manualmente:

```powershell
pwsh -File ~/.{{ARNES}}/scripts/Generar-CodeGraph.ps1 `
  -WTPath "<ruta absoluta al WT>" `
  -OutputRoot "~/.{{ARNES}}/projects/<identidad>/codegraph/WT01" `
  -WT "WT01"
```

El resumen se lee antes de abrir carpetas completas. Si el encargo requiere detalle, se abren archivos puntuales encontrados en `resumen.md` o `graph.json`.

## Reglas

- No escribir CodeGraph dentro del repo del producto.
- No copiar `graph.json` al producto ni a Issues.
- En un handoff, mencionar sólo ruta, HEAD y una conclusión breve cuando ayude a retomar.
- Si se deriva documentación útil para el producto, convertirla en documentación normal y sanitizada dentro del PR.
- Regenerar cuando cambie el `HEAD` o cuando el diff del WT altere arquitectura, dependencias o puntos de entrada.
