# Finanzas Kulifay

App de finanzas del hogar: ingresos, gastos, presupuesto por grupo, posibles fugas y gráficos.
Se instala en el celular como una app (PWA), los datos se guardan en **Supabase** y la app se publica gratis con **GitHub Pages**.

## Qué hay en esta carpeta

| Archivo | Para qué sirve |
|---|---|
| `index.html` | La app completa |
| `config.js` | Los datos de conexión con tu Supabase (lo completás en el paso 1.5) |
| `manifest.webmanifest`, `sw.js`, `icons/` | Lo que hace que se pueda instalar en el celular |
| `supabase/schema.sql` | Crea la base de datos y carga los datos que ya tenían |
| `supabase/functions/analizar/index.ts` | La función de IA (etapa 2) |

---

## Etapa 1: la app funcionando entre los dos (gratis)

### 1. Supabase (la base de datos)

1. Entrá a [supabase.com](https://supabase.com) y creá una cuenta (podés entrar con GitHub).
2. Tocá **New project**. Nombre: `finanzas-kulifay`. Inventá una contraseña de base de datos y guardala. Región: **South America (São Paulo)**. Plan: **Free**.
3. Cuando termine de crearse, andá a **SQL Editor → New query**. Abrí `supabase/schema.sql`, **cambiá `CORREO_DE_BELU@ejemplo.com` por el correo real de Belu**, pegá todo y tocá **Run**. Tiene que decir *Success*.
4. Andá a **Authentication → Users → Add user → Create new user**. Creá tu usuario (correo y contraseña) y tildá **Auto Confirm User**. Repetí con el de Belu. Tienen que ser los mismos correos del paso 3.
5. Andá a **Project Settings → API** (o **API Keys**). Copiá la **Project URL** y la clave **anon public** (o **publishable**). Pegalas en `config.js`:

   ```js
   supabaseUrl: 'https://xxxxxxxx.supabase.co',
   supabaseAnonKey: 'eyJhbGciOi...',
   ```

6. Por seguridad, en **Authentication → Sign In / Providers** desactivá **Allow new users to sign up**. Así nadie más puede crearse una cuenta.

### 2. GitHub (dónde vive la app)

1. Creá una cuenta en [github.com](https://github.com).
2. Tocá **New repository**. Nombre: `finanzas`. Dejalo en **Public** y tocá **Create repository**.
3. En la página del repositorio, tocá **uploading an existing file**. Arrastrá **todo el contenido** de esta carpeta (no la carpeta en sí: los archivos y subcarpetas que hay adentro) y tocá **Commit changes**.
4. Andá a **Settings → Pages**. En *Source* elegí **Deploy from a branch**, rama **main**, carpeta **/ (root)** y tocá **Save**.
5. En uno o dos minutos aparece arriba la dirección, por ejemplo `https://tu-usuario.github.io/finanzas/`. Esa es tu app.

### 3. Instalarla en el celular

- **Android (Chrome):** abrí la dirección, tocá el menú ⋮ y después **Instalar app** o **Agregar a pantalla principal**.
- **iPhone (Safari):** abrí la dirección, tocá **Compartir** y después **Agregar a inicio**.

Cada uno entra con su correo y contraseña. Lo que carga uno le aparece al otro en el momento.

### 4. Pasar datos de otra versión (si hace falta)

El `schema.sql` ya trae los grupos, conceptos y movimientos que había en la versión de claude.ai.
Si después cargan más cosas en otra versión, en esa versión vayan a **Importar Excel → Copia de seguridad → Descargar copia**.
Después, en la app nueva, usen **Restaurar una copia** con ese archivo.

---

## Cómo actualizar la app sin perder nada

Los datos viven en Supabase y la app vive en GitHub: **son cosas separadas**. Cambiar colores, textos o agregar funciones no toca los datos.

1. En GitHub, entrá al repositorio y abrí el archivo que querés cambiar (por ejemplo, `index.html`). Tocá el lápiz ✏️, o subí la versión nueva con **Add file → Upload files**.
2. Abrí `sw.js` y subí el número de versión: `fk-v1` → `fk-v2`. Con eso, los celulares descargan la versión nueva la próxima vez que abren la app.
3. Tocá **Commit changes**. En uno o dos minutos está publicada.

Lo único que hay que cuidar es no cambiar los **nombres de los campos** de los datos (`monto`, `fecha`, `conceptoId`, etc.). Si algún día hace falta, se hace con una migración, y Claude te puede ayudar con eso.

---

## Etapa 2: sumar la IA (análisis del mes y lectura del resumen bancario)

La app ya está preparada. Solo falta conectar tu propia cuenta de la API de Claude. Se paga por uso: cada análisis cuesta centavos de dólar.

1. Creá una cuenta en [console.anthropic.com](https://console.anthropic.com), cargá crédito (por ejemplo, USD 5) y en **Limits** poné un límite de gasto mensual.
2. En **API Keys**, creá una clave y copiala. Es secreta: no la pegues en GitHub ni en `config.js`.
3. En Supabase, andá a **Edge Functions → Deploy a new function → Via Editor**. Nombre: **`analizar`**. Pegá el contenido de `supabase/functions/analizar/index.ts` y tocá **Deploy**. Dejá activado **Verify JWT**.
4. En **Edge Functions → Secrets**, agregá:
   - `ANTHROPIC_API_KEY` = la clave del paso 2.
   - `CLAUDE_MODEL` = el modelo a usar (opcional; por defecto, `claude-sonnet-5-5`). La lista de modelos vigentes está en la [documentación de modelos](https://docs.claude.com/en/docs/about-claude/models/overview).
5. En GitHub, editá `config.js` y poné `ia: true`. Subí también la versión en `sw.js`.

Listo: los botones **Analizar este mes** y **Subir resumen bancario** pasan a usar tu IA.

**Cómo funciona:** la app lee el PDF en el celular, le manda el texto a tu función de Supabase, la función verifica que seas de la familia y le consulta a Claude con tu clave guardada. La respuesta vuelve a la app y ustedes revisan y guardan los movimientos.

**Límites a tener en cuenta:**

- Resúmenes muy largos pueden tardar más de un minuto. Si alguno no termina, subilo de a una página (como foto).
- Si el PDF es escaneado (no tiene texto), subí una foto o captura de cada página.
