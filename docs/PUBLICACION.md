# Publicación del arnés en el remoto propio

Se hace **una vez por cuenta u organización de GitHub**. Crea en esa cuenta un repo privado con una copia limpia del arnés, sin el historial de LesslieLoop, configurada con los datos de quien lo adopta. Después, cada PC se instala desde ese repo nuevo siguiendo la [instalación](INSTALACION.md); nunca desde el clon de LesslieLoop.

| Procedimiento | Cuándo | Desde dónde | Qué cambia |
| --- | --- | --- | --- |
| Publicación (esta guía) | Una vez por cuenta | Clon de LesslieLoop | Crea `<cuenta>/<arnés>` y, si falta, el repo de coordinación |
| [Instalación](INSTALACION.md) | Una vez por PC y tras cada actualización | Clon de `<cuenta>/<arnés>` | Skills, reglas, plantillas y scripts en la carpeta personal |

## Requisitos

Git, PowerShell 7 o Windows PowerShell 5.1 y GitHub CLI con sesión iniciada (`gh auth login`) en una cuenta que pueda crear repos en la cuenta u organización destino.

## Pasos

1. Clonar LesslieLoop en una carpeta de trabajo y entrar en ella:

   ```powershell
   git clone https://github.com/LesslieChao/LesslieLoop.git
   cd LesslieLoop
   ```

2. Ejecutar:

   ```powershell
   pwsh -File scripts/Publicar-Arnes.ps1
   ```

3. Responder los datos:
   - **Nombre de quien aprueba**: la persona que aprueba merges y promociones.
   - **Cuenta u organización de GitHub**: dueña del repo nuevo; también firma el commit.
   - **Email de commits**: preferentemente el noreply de GitHub de esa cuenta.
   - **Nombre del repo del arnés**: nombre del repo nuevo, también usado para la carpeta de estado `~/.<arnés>`.
   - **Repo de coordinación**: repo privado para Issues entre WT; por defecto, `<cuenta>/SharedCord`.

El script entonces:

1. Copia los archivos versionados de la revisión actual a una carpeta nueva, por defecto junto al clon y con el nombre del arnés. Exige que el clon no tenga cambios sin commit y que el destino esté vacío.
2. Reemplaza los marcadores por los datos elegidos en reglas, skills, documentación y plantillas. No modifica `LICENSE`, `NOTICE`, `PROVENANCE.md`, las líneas de copyright ni los scripts de publicación e instalación. Guarda los datos en `instalacion.json`.
3. Crea un repo Git nuevo con un único commit firmado con la cuenta y el email indicados, y las ramas `main` y `dev` en ese commit.
4. Crea `<cuenta>/<arnés>` privado en GitHub, sube `main` y `dev`, deja `dev` como rama predeterminada y crea la etiqueta `workflow` que usa la plantilla de Issue "Evento observado". Se detiene si ese repo ya existe.
5. Verifica que el repo de coordinación exista y sea privado. Si no existe, ofrece crearlo desde `plantilla-coordinacion/` con sus etiquetas.

Al terminar, el clon de LesslieLoop ya no se necesita. Seguir con la [instalación](INSTALACION.md) en cada PC.

Opciones: `-Si` acepta los datos pasados como parámetros (`-Aprobador`, `-Cuenta`, `-Email`, `-Arnes`, `-Coordinacion`) sin preguntar y falla si falta alguno; `-Destino <carpeta>` elige dónde armar el repo; `-SinPublicar` lo arma sólo en local e indica los comandos para publicarlo después; `-SinCoordinacion` omite el paso 5.

## Cambiar los datos más adelante

Ejecutar el mismo script desde un clon del repo ya publicado (tiene `instalacion.json`). Muestra los datos registrados y pide confirmarlos; si se corrigen, reemplaza los valores anteriores por los nuevos en todo el repo y crea un commit. No hace push: publicar ese commit con el flujo habitual del repo y volver a instalar en cada PC.
