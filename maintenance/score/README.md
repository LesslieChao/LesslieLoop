# Score de impacto de contexto

Este directorio es un instrumento interno de mantenimiento del arnés. No forma parte del flujo operativo de proyectos, no se instala como skill y no se copia a productos.

Sirve para registrar incidencias o decisiones del arnés que pueden afectar consumo de contexto/tokens, y recalcular una muestra viva de scores relativos a medida que aparecen más casos.

## Modelo

Cada evento conserva pesos brutos. El score `1-100` no es absoluto: se normaliza contra la muestra registrada en `events.jsonl`. Un único evento obtiene 100; al registrarse otro del mismo peso, ambos pasan a 50; si llega un tercero con el doble de peso, quedan 25, 25 y 50.

El registro empieza vacío y sólo incorpora eventos reales. Cada uno ocupa una línea JSON con `id` correlativo (`CTX-0001`, `CTX-0002`, …), fecha, origen y referencia.

Campos principales:

- `passive_weight`: costo estimado si la regla existe pero no se invoca.
- `invoked_weight`: costo estimado cuando se invoca el flujo relacionado.
- `savings_weight`: ahorro esperado cuando el guard evita trabajo erróneo o lectura innecesaria.

Los pesos son comparativos y pueden ajustarse con nuevas evidencias. El historial debe permanecer sanitizado: no incluir secretos, rutas locales, nombres de chats reales ni detalles privados de producto.

## Uso

Desde la raíz del arnés:

```powershell
python maintenance/score/score.py
python maintenance/score/score.py --json
```

El script sólo lee `events.jsonl` y calcula scores. No modifica Issues, archivos operativos, OWNERS, HANDOFF ni repos de producto.
