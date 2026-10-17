# Git

git y la CLI de GitHub (`gh`) se instalan desde `Brewfile`. La configuración se divide en dos archivos:

| Archivo | Lo escribe | Contenido |
|---|---|---|
| `~/.gitconfig` | El paso `dotfiles` (desde el repo) | Configuración común. Se reemplaza en cada instalación si cambió |
| `~/.gitconfig.local` | El paso `git` (una sola vez) | Tu identidad. **Nunca** está en el repo |

## `~/.gitconfig`

```ini
[core]
	autocrlf = input

[include]
	path = ~/.gitconfig.local
```

| Clave | Efecto |
|---|---|
| `core.autocrlf = input` | Si un archivo llega con finales de línea de Windows (`CRLF`), git los guarda como `LF` en el commit. Al hacer checkout no los cambia |
| `include.path` | Carga `~/.gitconfig.local`. Va al final, así lo que pongas ahí gana sobre lo de arriba |

El `.gitconfig` original tenía una sección `[filter "lfs"]`. La quité porque git-lfs no está instalado. Si lo instalas, `git lfs install` la vuelve a crear.

## Identidad (`~/.gitconfig.local`)

```ini
[user]
	name = Tu Nombre
	email = tu@email.com
```

El paso `git` la crea así:

1. Si `~/.gitconfig.local` ya tiene nombre y email, no hace nada.
2. Si no, busca los valores en tu `.gitconfig` anterior (el que respaldó el paso `dotfiles`) y te los propone. <kbd>Enter</kbd> acepta.
3. Con `--yes` usa esos valores sin preguntar. Si no encuentra ninguno, avisa y sigue.

Para cambiarla después:

```bash
git config --file ~/.gitconfig.local user.name "Tu Nombre"
git config --file ~/.gitconfig.local user.email "tu@email.com"
```

!!! tip "Tu configuración personal va en `~/.gitconfig.local`"
    `~/.gitconfig` lo reemplaza el setup en cada instalación (con backup). Lo que quieras conservar solo en tu Mac, como una llave de firma o un `credential.helper`, ponlo en `~/.gitconfig.local`.

## Lo que se integra con git

| Pieza | Qué aporta | Detalle |
|---|---|---|
| `EDITOR="code --wait"` | git abre los mensajes de commit y los rebases en VS Code | [Shell](shell.md#variables-startersh) |
| Plugin `git` de oh-my-zsh | Aliases como `gst` (`git status`), `gco` (`git checkout`), `gp` (`git push`) | [Shell](shell.md#plugins-de-oh-my-zsh) |
| Función `gmain` | Guarda tus cambios, cambia a `main`, hace `pull` y los restaura | [Shell](shell.md#funciones) |
| Prompt powerlevel10k | Rama y estado del repo (cambios, commits por subir o bajar) | [Shell](shell.md#prompt-powerlevel10k) |
| VS Code `git.autofetch` | Hace `git fetch` cada cierto tiempo | [Editor](editor.md#settingsjson) |
| `gh` | Pull requests, issues y repos desde la terminal. Inicia sesión con `gh auth login` | |
