# Claude Code

El paso `claude` (`steps/70-claude.sh`) hace tres cosas:

1. Instala Claude Code con el instalador oficial (`~/.local/bin/claude`). Si ya está instalado, no lo toca. Se actualiza solo.
2. Copia los archivos de `manifest.claude.txt`: `~/.claude/CLAUDE.md` y `~/.claude/settings.json`. Si ya tienes alguno distinto, lo respalda en `~/.dotfiles-backup/<timestamp>/` antes de reemplazarlo.
3. Si tienes Herdr, reinstala su integración (`herdr integration install claude`). Ver [Herdr](#herdr).

!!! tip "¿Ya tienes tu propia configuración de Claude Code?"
    Usa `./install.sh --skip claude` y queda tal cual.

## `CLAUDE.md` global

`~/.claude/CLAUDE.md` contiene instrucciones que Claude Code carga al inicio de **cada** sesión, en cualquier proyecto. Complementa el `CLAUDE.md` de cada repositorio, que guarda el contexto específico de ese proyecto.

### ¿Por qué en inglés?

El archivo está en inglés a propósito. Este documento lo explica en español.

- **Tokens:** los tokenizers se entrenan con texto mayoritariamente en inglés. El mismo contenido en español suele ocupar más tokens, por los acentos, las conjugaciones y las palabras más largas.
- **Por qué importa aquí:** este archivo se carga en cada sesión y ocupa ventana de contexto todo el tiempo. Ahorrar tokens en algo que siempre está presente rinde más que ahorrarlos en un prompt suelto.
- **Matiz 1:** con prompt caching el costo monetario baja mucho. La ganancia principal es espacio de contexto, no dinero.
- **Matiz 2:** los modelos actuales siguen instrucciones en español sin problema. El inglés es una optimización, no un requisito.
- **Matiz 3:** las reglas pueden estar en inglés y la conversación en español. Claude responde en el idioma en que le escribes.

No hay una cifra exacta de ahorro: depende del tokenizer y del texto. Si quieres medirlo, compara ambas versiones con el endpoint de [token counting](https://docs.anthropic.com/en/docs/build-with-claude/token-counting) de la API.

## Las reglas, una por una

Cada regla tiene tres partes: **qué** pide, **por qué** existe y un **ejemplo** del comportamiento que produce. Los encabezados usan el nombre original en inglés para que encuentres la regla en el archivo.

### 1. Interaction Style

#### Zero Fluff
- **Qué:** respuestas cortas y centradas en código. Sin saludos, introducciones ni resúmenes de cortesía.
- **Por qué:** el texto de relleno cuesta tokens y tiempo de lectura, y no aporta nada.
- **Ejemplo:** a "¿cómo borro una rama remota?" responde `git push origin --delete mi-rama`, sin "¡Claro! Con gusto te ayudo…".

#### Direct Resolution
- **Qué:** dar la mejor solución. Las alternativas, solo si las pides.
- **Por qué:** una lista de cinco opciones te pasa a ti el trabajo de decidir.
- **Ejemplo:** para parsear JSON en bash propone `jq` directamente, sin comparar `jq`, `python -m json.tool` y `node -e`.

### 2. Token Efficiency & Context Management

#### Log Offloading
- **Qué:** si un log o la salida de un comando pasa de 30 líneas, lo lee un sub-agente aislado que devuelve solo lo relevante.
- **Por qué:** un log de 2000 líneas llena la ventana de contexto de la sesión principal, y casi todo es ruido.
- **Ejemplo:** un `npm test` con 400 líneas de salida lo revisa un sub-agente, que responde "falla `auth.test.ts:42`, esperaba 200 y recibió 401".

#### Context Optimization (60% Rule)
- **Qué:** recomendar `/compact` cuando el contexto vaya por el 60 %, mucho antes de que la compactación automática se dispare sola.
- **Por qué:** compactar a tiempo, en un punto natural (por ejemplo, al terminar un ticket), da un resumen más limpio que una compactación forzada a mitad de una tarea.
- **Ejemplo:** al cerrar un ticket largo, termina con "Recomiendo /compact antes del siguiente".

#### Milestone Pruning
- **Qué:** al terminar un hito importante, resumir el avance y avisar si conviene `/clear`.
- **Por qué:** el contexto de una tarea ya cerrada estorba en la siguiente y puede confundir al modelo.
- **Ejemplo:** al cerrar una Epic, resume lo hecho en pocas líneas y sugiere `/clear` antes de empezar algo no relacionado.

#### Batch Operations
- **Qué:** agrupar varias ediciones en una sola llamada, y agrupar requisitos, casos límite y preferencias de testing en una sola pregunta.
- **Por qué:** cada ida y vuelta cuesta tokens y tu tiempo.
- **Ejemplo:** en vez de preguntar tres cosas en tres mensajes, hace una lista con las tres.

### 3. Context Isolation

#### Explicit Referencing
- **Qué:** preferir referencias exactas a archivos (`@src/app.ts`) en vez de recorrer directorios enteros.
- **Por qué:** explorar un repo grande gasta mucho contexto para encontrar un solo archivo.
- **Ejemplo:** si mencionas `@lib/utils.sh`, lee ese archivo en lugar de listar todo `lib/`.

#### Ignore Artifacts
- **Qué:** buscar un `.claudeignore` y respetarlo, para no leer builds ni dependencias (`node_modules/`, `dist/`…).
- **Por qué:** esos archivos son enormes y casi nunca son relevantes.
- **Ejemplo:** con `dist/` en `.claudeignore`, no abre el bundle compilado aunque contenga el texto buscado.
- **Nota:** Claude Code no trata `.claudeignore` como un archivo especial; esta regla hace que Claude lo respete por convención. Para bloquear lecturas de verdad, usa `permissions.deny` en el `settings.json` del proyecto.

### 4. Git Strategy

#### Incremental Commits
- **Qué:** hacer commit de los cambios al terminar cada ticket.
- **Por qué:** commits pequeños se revisan y se revierten fácilmente.
- **Ejemplo:** tres tickets terminados son tres commits, no uno gigante al final.

#### Conventional Commits
- **Qué:** usar prefijos [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `refactor:`, `docs:`…
- **Por qué:** el historial se lee de un vistazo y permite generar changelogs.
- **Ejemplo:** `fix: quote brew cache path in cleanup`.

#### Ticket Tracking
- **Qué:** incluir la Epic y el ticket en el mensaje.
- **Por qué:** cada commit queda ligado a su tarea en `OBJECTIVES.md`.
- **Ejemplo:** `feat(Epic 1.2): add commentary API endpoint`.

#### No Auto-Push
- **Qué:** nunca hacer `git push` por iniciativa propia.
- **Por qué:** publicar es difícil de deshacer. Tú revisas los commits y decides cuándo subirlos.
- **Ejemplo:** termina con "Commit `a1b2c3d` listo" y deja el push en tus manos.

### 5. Human Intervention

#### Action Required Banners
- **Qué:** cuando termina algo o necesita que hagas algo, muestra un banner muy visible con arte ASCII y emojis.
- **Por qué:** en una salida larga, la acción que te toca no debe perderse entre el texto.
- **Ejemplo:**

  ```
  ╔══════════════════════════════════════╗
  ║  ⚠️  ACCIÓN REQUERIDA                 ║
  ║  ▶️  Ejecuta: bats tests/             ║
  ╚══════════════════════════════════════╝
  ```

### 6. Objective Work

Esta sección define cómo se aborda una tarea compleja.

#### Product Manager y Lead Architect primero
- **Qué:** ante una tarea nueva, analizarla como PM y arquitecto antes de programar. Si falta contexto, hay casos límite sin definir o el diseño es ambiguo, se **detiene** y te hace una lista corta de preguntas.
- **Por qué:** suponer mal al principio sale mucho más caro que preguntar.
- **Ejemplo:** a "agrega login" responde preguntando: ¿email o OAuth?, ¿sesiones o JWT?, ¿qué pasa con usuarios existentes?

#### Feature Context & Architecture (`EXECUTION_PLAN.md`)
- **Qué:** si la tarea vale 3 story points o más, antes de tocar código escribe `EXECUTION_PLAN.md` con cuatro apartados:
  - **Feature Goal**: qué logra la feature, en pocas líneas.
  - **Data & State Changes**: esquemas, modelos o estructuras de estado nuevos.
  - **System Integration**: qué componentes se crean y cuáles existentes cambian.
  - **Edge Cases & Logic**: reglas, manejo de errores y flujos que pide la tarea.
- **Por qué:** una tarea larga cruza varias sesiones (y compactaciones). El plan en disco mantiene las decisiones aunque el contexto se pierda.
- **Ejemplo:** este repositorio se construyó así: el plan guardaba decisiones como "copiar en vez de symlink" o "no tocar la Mac del autor".

#### Task Breakdown (`OBJECTIVES.md`)
- **Qué:** dividir el plan en Epics (hitos) y tickets (tareas concretas) con un formato fijo.
- **Por qué:** tareas pequeñas se pueden verificar una por una.
- **Ejemplo:** `## Epic 6: Claude Code` con `- [ ] 4. docs/claude-code.md…`.

#### Status Tracking
- **Qué:** cada ticket lleva un estado: `[ ]` sin empezar, `[/]` en progreso, `[x]` terminado.
- **Por qué:** al retomar en otra sesión se sabe exactamente dónde se quedó.
- **Ejemplo:** tras compactar, Claude abre `OBJECTIVES.md`, ve el `[/]` y continúa ese ticket.

#### Strict Serialization
- **Qué:** un solo ticket a la vez.
- **Por qué:** cambios mezclados son difíciles de revisar y de revertir.
- **Ejemplo:** no empieza la documentación mientras el ticket de tests sigue abierto.

#### Start
- **Qué:** al empezar un ticket, lo marca `[/]`.
- **Por qué:** el archivo refleja siempre el trabajo en curso.
- **Ejemplo:** `- [/] 4. docs/claude-code.md…`.

#### Stop
- **Qué:** al terminar, lo marca `[x]` y se **detiene** hasta que escribas `continue`.
- **Por qué:** te da un punto de control para revisar, probar o cambiar el rumbo entre tickets.
- **Ejemplo:** termina con un banner "Escribe `continue` para el Ticket 7.1".

#### Interruptions
- **Qué:** si la respuesta se corta, con `continue` retoma exactamente donde se quedó, y el ticket sigue en `[/]`.
- **Por qué:** evita marcar como terminado algo a medias.
- **Ejemplo:** un archivo a medio escribir se completa, no se vuelve a empezar desde otro punto.

#### Cleanup
- **Qué:** cuando todos los tickets están en `[x]`, borra `OBJECTIVES.md` y archiva o borra `EXECUTION_PLAN.md`.
- **Por qué:** son archivos de trabajo temporales; no deben quedarse en el repositorio.
- **Ejemplo:** el último commit de una feature elimina ambos archivos.

#### Handling Scope Creep & Bugs
- **Qué:** si aparece un bug, una dependencia faltante o un cambio de arquitectura, no lo arregla en silencio: agrega un ticket nuevo y te pregunta qué prioridad darle.
- **Por qué:** mantiene cada ticket dentro de su alcance y te deja decidir.
- **Ejemplo:** mientras escribe tests encuentra que `cleanup` no espera confirmación; agrega "🐛 `cleanup`…" a `OBJECTIVES.md` y pregunta si lo arregla ya o después.

#### Rollback Rule
- **Qué:** si un cambio rompe el build o los tests, revierte el archivo en vez de apilar parches, aísla el error y pide guía.
- **Por qué:** cinco parches sobre un error mal entendido suelen dejar el código peor que al principio.
- **Ejemplo:** un refactor rompe 10 tests: lo revierte, identifica qué función causó la falla y te pregunta cómo seguir.

### 7. Keep Docs Current

#### Keep Docs Current
- **Qué:** después de cada cambio, actualizar `CLAUDE.md` y `README.md` del proyecto si hace falta (comandos nuevos, cambios de arquitectura, reglas nuevas).
- **Por qué:** documentación desactualizada engaña tanto a personas como a Claude en la siguiente sesión.
- **Ejemplo:** al agregar el flag `--skip`, también se agrega a la sección de comandos del `README.md`.

### 8. Code Standards & Architecture

#### Idiomatic Execution
- **Qué:** escribir código idiomático del lenguaje.
- **Por qué:** el código idiomático es más fácil de leer y mantener para cualquiera que conozca el lenguaje.
- **Ejemplo:** scripts bash con `set -euo pipefail`; type hints en Python; manejo de errores con `if err != nil` en Go.

#### Strict Typing
- **Qué:** tipos estrictos donde el lenguaje los tenga (TS, C#, Go, Python). Nada de `any` u `object` genéricos.
- **Por qué:** los tipos detectan errores antes de ejecutar y documentan la intención.
- **Ejemplo:** `function parseUser(raw: unknown): User` en vez de `function parseUser(raw: any): any`.

#### Clean Code Principles
- **Qué:** guard clauses (retornos tempranos), funciones modulares de menos de ~50 líneas y nombres descriptivos sin abreviaturas.
- **Por qué:** menos anidamiento y mejores nombres hacen que el código se explique solo.
- **Ejemplo:** `if [[ -z "$entries" ]]; then return 0; fi` al principio, en vez de envolver toda la función en un `if`; `manifest_entries` en vez de `me`.

#### Architectural Match
- **Qué:** seguir la estructura y los patrones que ya tiene el proyecto, sin introducir paradigmas nuevos.
- **Por qué:** un proyecto con un solo estilo es más fácil de recorrer.
- **Ejemplo:** en este repo, un paso nuevo va en `steps/NN-nombre.sh` y usa `run_cmd` de `lib/`, aunque otro enfoque también funcionaría.

### 9. Testing, QA & Sandbox Execution

#### Sandbox Awareness
- **Qué:** asumir que algunos comandos (`npm`, `dotnet`, `go mod`, migraciones) pueden no estar disponibles en el entorno de Claude.
- **Por qué:** evita que Claude insista con comandos que no puede ejecutar.
- **Ejemplo:** si `dotnet` no existe, no intenta instalarlo: te pasa el comando.

#### Execution Handoffs
- **Qué:** si un ticket requiere correr tests, instalar dependencias o compilar y no puede hacerlo, te da el comando exacto con un banner y espera a que pegues la salida.
- **Por qué:** tú controlas lo que corre en tu máquina, y el ticket no se da por bueno sin un resultado real.
- **Ejemplo:** "▶️ Ejecuta `npm run migrate` y pega la salida".

#### Test Coverage
- **Qué:** al escribir utilidades o lógica compleja, agregar o actualizar sus tests unitarios.
- **Por qué:** los tests protegen la lógica de regresiones futuras.
- **Ejemplo:** la comparación de `settings.json` ignorando `hooks` llegó con tres tests en `tests/claude.bats`, incluido uno que falla sin el arreglo.

#### Verification Gate
- **Qué:** no marcar un ticket `[x]` sin verificarlo, sea con herramientas disponibles o con la salida que tú pegues.
- **Por qué:** "debería funcionar" no es lo mismo que "funciona".
- **Ejemplo:** antes de cerrar un ticket corre `bats tests/` y confirma que todo pasa.

## `settings.json`

`~/.claude/settings.json` es la configuración de usuario de Claude Code. La versión del repo (`home/.claude/settings.json`) está limpia: no incluye `autoMode` (tiene detalles de proyectos privados) ni `hooks` (Herdr los regenera).

| Clave | Valor | Qué hace |
|---|---|---|
| `effortLevel` | `"xhigh"` | Nivel de esfuerzo de razonamiento por defecto. Más alto = respuestas más pensadas, pero más lentas y con más tokens. |
| `modelSettings` | `claude-sonnet-5` y `claude-opus-5-5` en `"high"` | Ajustes por modelo. Aquí sobrescribe `effortLevel` para esos dos modelos. |
| `tui` | `"fullscreen"` | La interfaz ocupa toda la terminal. |
| `theme` | `"dark-ansi"` | Tema oscuro que usa los 16 colores ANSI de la terminal, así respeta la paleta de Ghostty (Catppuccin). |
| `autoCompactEnabled` | `true` | Compacta el contexto automáticamente cuando se llena. La regla del 60 % recomienda hacerlo antes a mano; esto es la red de seguridad. |

!!! tip "Personalizar"
    - En tu máquina, edita `~/.claude/settings.json`. `theme` también se cambia con `/theme`, y la compactación automática con `/config`.
    - Si vuelves a correr `install.sh`, se reemplaza el archivo (con respaldo). Para evitarlo, usa `--skip claude`.
    - En tu fork, edita `home/.claude/settings.json`. No agregues claves privadas: `tests/repo.bats` falla si aparecen `autoMode`, `hooks`, `env` o `apiKeyHelper`.
    - Para quitar una clave, bórrala: Claude Code usa su valor por defecto.

## Skills y plugins

No se versionan. Las skills y plugins que aparecen en `~/.claude/skills/synced/` y `~/.claude/plugins/synced/` se sincronizan desde tu cuenta de claude.ai al iniciar sesión con `claude`. Los plugins de marketplaces (como `claude-plugins-official`) se instalan desde Claude Code con `/plugin`.

Tampoco se versiona el estado privado: `~/.claude.json`, `history.jsonl`, `projects/`, `sessions/`, `file-history/` ni `stats-cache.json`.

## Herdr

Herdr muestra el estado de cada agente (trabajando, esperando, terminado). Para eso agrega un hook (`herdr-agent-state`) al `settings.json` de Claude.

Como el `settings.json` del repo no trae `hooks`, el paso `claude` hace esto:

1. Copia `settings.json`.
2. Revisa si el hook de Herdr está activo: `herdr integration status` dice `claude: current` y el hook aparece en `settings.json`.
3. Si no lo está, ejecuta `herdr integration install claude`.

En siguientes ejecuciones, `settings.json` se compara **ignorando** `hooks`. Si la única diferencia es el hook de Herdr, el archivo no se toca. Si Herdr no está instalado, el paso solo muestra un aviso.
