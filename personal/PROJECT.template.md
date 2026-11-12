# Proyecto operativo

- Identidad estable: `<owner>/<repo>` o `local/<nombre>` acordado; conservarla si luego cambia el remoto
- Carpeta contenedora seleccionada como proyecto en Codex y Claude:
- Checkout administrativo (`<contenedor>/repo`):
- Directorio de worktrees (`<contenedor>/worktrees`):
- Directorio Git común (resultado de `git rev-parse --git-common-dir`, resuelto a ruta absoluta):
- Remoto `origin`: pendiente / URL
- Rama base de trabajo:
- Identidad Git autorizada para commits:
  - `user.name`: {{CUENTA_GITHUB}}
  - `user.email`: {{EMAIL}} (confirmar por proyecto; no commitear si falta o no coincide exactamente)
- Repositorio privado de coordinación: `{{COORDINACION}}`
- Revisión de `{{ARNES}}`: commit SHA
- Ubicación de la copia instalada del arnés:
- Fecha de alta:

## Perfil particular

- Convención de ramas:
- Convención de carpetas: `<contenedor>/worktrees/WTxx - Título`
- Comandos de validación y directorio desde el que se ejecutan:
- Documentación técnica que consultar:
- Restricciones específicas del producto:
- Excepciones al flujo general, motivo y aprobación:
- Copias o repositorios de historia independiente que NO son WT de este producto:

## Cambios del registro

| Fecha | Cambio y motivo | Revisión del arnés adoptada |
| --- | --- | --- |

Registrar aquí cambios de configuración, sin transcripciones. Antes de actualizar el arnés comparar las adaptaciones particulares; actualizar la revisión sólo después de verificar compatibilidad. `OWNERS.md` es la fuente del estado de los WT, no duplicar sus filas aquí.

## Límites

- El repositorio del producto contiene código y documentación publicable.
- La coordinación entre workers vive en el repositorio privado indicado arriba.
- Las rutas, handoffs y estados locales viven junto a este archivo y no se copian al producto.
