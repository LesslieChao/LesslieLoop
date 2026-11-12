# Evolución de este repositorio

- `main`: versión del arnés aceptada por {{APROBADOR}}; `dev`: integración de cambios del arnés.
- Las modificaciones se preparan en una rama feature y un PR hacia `dev`; {{APROBADOR}} aprueba el merge y el worker lo ejecuta. Promover `dev` a `main` requiere aprobación expresa de {{APROBADOR}}; con ella, la ejecuta el worker.
- Antes de crear commits, PR, push o merge, validar `user.name`, `user.email` y los commits propios a publicar, por ejemplo `origin/dev..HEAD`, con `~/.{{ARNES}}/scripts/Verificar-Identidad-Git.ps1` contra la identidad autorizada en PROJECT. Un email noreply no se infiere: si falta el valor exacto, detenerse.
- Las rutas de `plantilla-proyecto/` son las únicas que se copian a repos de producto. Revisar esto antes de cambiar el bootstrap.
- Probar que las skills de Codex y Claude Code describen el mismo contrato de cierre y apertura. No instalar en este ambiente reglas personales destinadas al equipo de {{APROBADOR}}.
- Antes de entregar cambios de plantillas ejecutar `python scripts/verificar_plantillas.py` y `git diff --check`. Revisar también el significado de los textos del producto; el análisis automático sólo detecta parte de las filtraciones.
- Al crear un WT de mantenimiento, actualizar `OWNERS.md` en este repo antes de intervenir otro territorio.
