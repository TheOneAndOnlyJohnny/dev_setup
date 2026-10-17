# Shell

zsh (el shell por defecto de macOS) con **oh-my-zsh** y el prompt **powerlevel10k**.

## Qué instala el paso `zsh`

`steps/30-zsh.sh` clona con `git clone --depth=1`:

| Destino | Repositorio |
|---|---|
| `~/.oh-my-zsh` | [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) |
| `custom/themes/powerlevel10k` | [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k) |
| `custom/plugins/you-should-use` | [MichaelAquilina/zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) |
| `custom/plugins/zsh-autosuggestions` | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| `custom/plugins/zsh-completions` | [zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions) |
| `custom/plugins/zsh-history-substring-search` | [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) |
| `custom/plugins/zsh-syntax-highlighting` | [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |

- No usa el instalador de oh-my-zsh: ese reescribe `~/.zshrc`, y aquí `~/.zshrc` viene del repo.
- Si un clon ya existe, no lo toca. Actualízalos con `omz update` (o el alias `bu`).
- Si existe la carpeta pero no es un clon de git, el paso falla y te pide moverla.
- Si tu shell de login no es zsh, avisa con el comando para cambiarlo: `chsh -s /bin/zsh`.

## Archivos

| Archivo | Contenido |
|---|---|
| `~/.zprofile` | Homebrew (`brew shellenv`: `PATH`, completions) y la integración de OrbStack. Lo carga el shell de login, antes de `.zshrc` |
| `~/.zshrc` | Una sola línea: carga `~/.dotfiles/starter.sh` |
| `~/.dotfiles/starter.sh` | Variables, plugins, tema, y carga el resto de archivos |
| `~/.dotfiles/setup_aliases.sh` | Aliases |
| `~/.dotfiles/setup_functions.sh` | Funciones |
| `~/.dotfiles/setup_keybindings.sh` | Atajos de teclado |
| `~/.p10k.zsh` | Configuración del prompt |

### Variables (`starter.sh`)

| Variable | Valor | Para qué |
|---|---|---|
| `EDITOR`, `VISUAL` | `code --wait` | git y otras herramientas abren VS Code y esperan a que cierres el archivo |
| `GOPATH` | `~/go` | Módulos y binarios de Go |
| `BUN_INSTALL` | `~/.bun` | Paquetes globales de bun (`~/.bun/bin` va al `PATH`) |
| `HOMEBREW_NO_AUTO_UPDATE` | `1` | `brew install` no actualiza Homebrew cada vez |
| `HOMEBREW_NO_ASK` | `1` | Homebrew no pide confirmación |
| `PATH` | `+ ~/.local/bin` | Ahí vive el binario de Claude Code |
| `PATH` | `+ mysql-client/bin` | `mysql-client` es *keg-only*: Homebrew no lo enlaza solo |

### Plugins de oh-my-zsh

| Plugin | Qué hace |
|---|---|
| `git` | Aliases de git (`gst`, `gco`, `gp`…) |
| `zsh-syntax-highlighting` | Colorea el comando mientras lo escribes; en rojo si no existe |
| `zsh-autosuggestions` | Sugiere en gris el comando según tu historial; <kbd>→</kbd> lo acepta |
| `you-should-use` | Te avisa cuando escribes un comando que ya tiene alias |
| `zsh-completions` | Completions extra para muchas herramientas |
| `zsh-history-substring-search` | Busca en el historial lo que llevas escrito (ver atajos) |
| `jsontools` | `pp_json`, `is_json`, `urlencode_json`… |

### Aliases

| Alias | Comando |
|---|---|
| `t` | `tail -f` |
| `bu` | `brew update && brew upgrade && brew cleanup && omz update` |
| `ghosttyc` | Abre la configuración de Ghostty en VS Code |
| `dcu` / `dcd` / `dcl` | `docker-compose up -d` / `down` / `logs -f` (Docker lo da OrbStack) |
| `b` / `bx` / `bi` / `br` / `bt` | `bun` / `bunx` / `bun install` / `bun run` / `bun test` |

### Funciones

| Función | Qué hace |
|---|---|
| `genpass` | Contraseña aleatoria de 20 caracteres, en grupos de 6 separados por `-` |
| `genpass strong` | 20 caracteres con letras, números y símbolos |
| `genpass uuid` | UUID en minúsculas |
| `gmain` | Guarda tus cambios con `git stash`, cambia a `main` (o `master`), hace `pull` y restaura los cambios. Si el `stash pop` choca, tus cambios quedan en `git stash list` |
| `cleanup` | Limpia cachés y logs de usuario y de `/Library`, la caché de DNS y de fuentes, `DerivedData` de Xcode y la caché de Homebrew, y libera memoria inactiva. Pide <kbd>Enter</kbd> antes de empezar y tu contraseña para `sudo`. No toca `/System` ni `/private/var/log`. Al terminar, reinicia la Mac |

!!! danger "`cleanup` borra sin papelera"
    Usa `rm -rf` y `sudo`. Cierra tus apps antes de correrlo: algunas pierden su caché o sus logs, y los vuelven a generar al abrir.

### Atajos de teclado

| Tecla | Acción |
|---|---|
| <kbd>↑</kbd> / <kbd>↓</kbd> | Recorre el historial filtrando por lo que ya escribiste. Escribe `git` y pulsa <kbd>↑</kbd> para ver solo comandos con `git` |

## Prompt (powerlevel10k)

Estilo **Pure** en dos líneas:

```
~/Workspace/dev_setup main ⇡1                       7s user@host
❯
```

- **Izquierda:** carpeta actual y estado de git.
- **Derecha:** duración del último comando (si tardó 5 s o más), virtualenv de Python y `user@host` (solo por SSH o como root).
- **Segunda línea:** `❯`, magenta si el último comando salió bien y rojo si falló.

Para rediseñarlo: `p10k configure`.

!!! warning "El asistente sobrescribe `~/.p10k.zsh`"
    Para conservar el cambio, cópialo a `home/.p10k.zsh` en el repo. Si no, la próxima instalación lo reemplaza (con backup).
