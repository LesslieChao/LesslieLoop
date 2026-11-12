# Revisión privada de entregas de producto

Aplicar al preparar una plantilla, documentación, commit o PR destinado a un producto sanitizado. Este documento permanece en el arnés; sus comprobaciones se registran en la coordinación privada.

## Documentación útil

- El cambio explica su comportamiento y tiene pruebas y resultados verificables.
- Se actualiza la documentación afectada de uso, arquitectura, configuración, operación, migraciones y limitaciones. Cuando no corresponde modificarla, el PR explica el motivo.
- Un mantenedor puede comprender y reproducir el cambio con la información del producto.

## Revisión de contenido

- Comprobar que no se incorporen secretos, datos operativos reales, rutas locales ni identificadores internos en ejemplos, capturas o configuraciones.
- Mantener fuera del producto las asignaciones de workers, nombres de chats o WT, handoffs, prompts y enlaces a coordinación privada.
- En proyectos Next.js, levantar dev servers desde sesiones de agente con `~/.{{ARNES}}/scripts/Iniciar-Sin-Deteccion-De-Agente.ps1`. Antes de commit, push o PR, ejecutar `~/.{{ARNES}}/scripts/Verificar-Artefactos-Agente-Next.ps1` para bloquear reglas de agente generadas por Next y `next-env.d.ts` apuntando a `.next/dev/types`.
- Antes de crear o actualizar un PR, commit, changelog o documentación del producto, revisar título y cuerpo para excluir referencias privadas: URLs o slugs del repo de coordinación, referencias `owner/repo#n` privadas, rutas `~/.{{ARNES}}`, `HANDOFF`, `OWNERS`, `WTxx`, nombres de chats y menciones al arnés. El PR debe explicar el cambio con contexto del producto, no con trazabilidad interna.
- Revisar también referencias indirectas: «documentación pública», «ejemplos sanitizados», «sin acceso a repositorios privados» y prohibiciones que enumeran el proceso interno. Reemplazarlas por requisitos concretos del producto; omitir las que sólo tienen sentido en la coordinación.
- Leer todo el contenido destinado al producto, incluidos archivos ocultos y plantillas de GitHub. Una búsqueda de palabras ayuda, pero no sustituye la revisión de significado.

La plantilla de producto conserva instrucciones normales de contribución y documentación. El control de sanitización y su resultado permanecen fuera de ella.
