# Editor (VS Code)

VS Code se instala desde `Brewfile` (perfil core). El paso `dotfiles` copia `settings.json` y el paso `vscode` instala las extensiones.

## Extensiones

`steps/60-vscode.sh` lee `vscode/extensions.txt` (un ID por línea) e instala solo las que faltan. Nunca actualiza las que ya tienes: VS Code las actualiza solo. Busca el comando `code` en el `PATH` y, si no está, dentro de la app.

| Grupo | Extensión | Para qué |
|---|---|---|
| Tema | `catppuccin.catppuccin-vsc` | Tema de colores Catppuccin |
| Tema | `catppuccin.catppuccin-vsc-icons` | Iconos de archivos Catppuccin |
| Web | `bradlc.vscode-tailwindcss` | Autocompletado de clases de Tailwind |
| Web | `dbaeumer.vscode-eslint` | ESLint |
| Web | `esbenp.prettier-vscode` | Formateo con Prettier |
| Web | `svelte.svelte-vscode` | Svelte |
| Datos | `cweijan.vscode-postgresql-client2` | Cliente de bases de datos (PostgreSQL, MySQL…) |
| Datos | `cweijan.dbclient-jdbc` | Drivers JDBC para el cliente anterior |
| Datos | `mikestead.dotenv` | Resaltado de archivos `.env` |
| Datos | `redhat.vscode-yaml` | YAML con validación de esquemas |
| Datos | `tamasfe.even-better-toml` | TOML |
| Herramientas | `alefragnani.project-manager` | Lista de proyectos para cambiar rápido entre ellos |
| Herramientas | `ms-azuretools.vscode-containers` | Contenedores (Docker de OrbStack) |

Para agregar una extensión: añade su ID a `vscode/extensions.txt`. Lo encuentras en la página de la extensión o con `code --list-extensions`.

## `settings.json`

Archivo: `~/Library/Application Support/Code/User/settings.json`

| Clave | Valor | Efecto |
|---|---|---|
| `workbench.colorTheme` | `Catppuccin Frappé` | Tema de colores |
| `workbench.preferredDarkColorTheme` | `Catppuccin Frappé` | Tema cuando macOS está en modo oscuro |
| `workbench.preferredLightColorTheme` | `Catppuccin Latte` | Tema cuando macOS está en modo claro |
| `workbench.iconTheme` | `catppuccin-frappe` | Iconos de archivos |
| `editor.fontFamily` | `IosevkaTerm NFM ExtraLight` | Fuente del editor. Ver [fuentes y colores](fonts-and-colors.md) |
| `editor.minimap.enabled` | `false` | Oculta el minimapa |
| `workbench.activityBar.location` | `top` | Barra de actividades arriba, no a la izquierda |
| `workbench.activityBar.compact` | `true` | Barra de actividades compacta |
| `workbench.startupEditor` | `none` | No abre la pestaña de bienvenida |
| `git.autofetch` | `true` | Hace `git fetch` periódicamente |
| `projectManager.git.baseFolders` | `["~/Workspace"]` | Project Manager detecta los repos de `~/Workspace` |
| `chat.titleBar.openInAgentsWindow.enabled` | `false` | Oculta el botón del chat de agentes en la barra de título |
| `svelte.enable-ts-plugin` | `true` | Los archivos TS entienden imports de componentes Svelte |

No hay `keybindings.json`: no uso atajos personalizados.

!!! tip "Los cambios desde VS Code no vuelven al repo"
    Si cambias un ajuste desde la interfaz de VS Code, el cambio queda solo en tu Mac y la próxima instalación lo reemplaza (con backup). Para conservarlo, cópialo a `home/Library/Application Support/Code/User/settings.json` en el repo.
