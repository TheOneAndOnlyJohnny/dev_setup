# Instalación

## Requisitos

- Una Mac con **Apple Silicon** (M1 o posterior).
- Una terminal **nativa**: la Terminal de macOS sirve. No uses una terminal que corra bajo Rosetta.
- Tu usuario normal, **sin `sudo`**. Homebrew te pedirá la contraseña cuando la necesite.
- Conexión a internet.

No necesitas nada más. Si faltan las Xcode Command Line Tools (que traen `git`), el setup las instala.

## Instalación rápida

```bash
git clone https://github.com/theoneandonlyjohnny/dev_setup.git
cd dev_setup
./install.sh --dry-run   # 1. revisa qué haría, sin cambiar nada
./install.sh             # 2. instala
```

!!! tip "Prueba primero con `--dry-run`"
    Imprime cada comando que correría y cada archivo que copiaría o respaldaría, sin tocar nada. Úsalo en una Mac que ya tiene configuración tuya.

## Opciones

| Opción | Efecto |
|---|---|
| `--full` | Instala también mis apps personales y de la App Store (`Brewfile.full`) |
| `--dry-run` | Imprime cada acción sin ejecutarla |
| `-y`, `--yes` | Responde "sí" a todo y no pregunta nada (modo no interactivo) |
| `--skip <paso>` | Omite un paso. Se puede repetir: `--skip vscode --skip claude` |
| `-h`, `--help` | Muestra la ayuda y la lista de pasos |

Se pueden combinar: `./install.sh --full --dry-run`.

## Qué hace cada paso

Los pasos corren en este orden. Si uno falla, el setup se detiene y te dice cuál; corrige el problema y vuelve a correr `./install.sh`. Los pasos que ya terminaron se saltan solos.

### 1. `preflight`

- Se detiene si no es macOS, si no es Apple Silicon, si la terminal corre bajo Rosetta o si lo corres como `root`.
- Si faltan las Xcode Command Line Tools, abre el instalador de macOS. **Acepta el diálogo**: el setup espera hasta que terminen (máximo 30 minutos) y sigue solo.

### 2. `homebrew`

Instala [Homebrew](https://brew.sh) con su instalador oficial si no lo tienes. Te pedirá tu contraseña. Con `--yes` lo instala sin preguntar, pero `sudo` ya debe estar autorizado (por ejemplo, corriendo `sudo -v` antes).

### 3. `packages`

Corre `brew bundle` con `Brewfile` y, con `--full`, con `Brewfile.full`. Detalle en [apps y paquetes](apps.md).

- Nunca actualiza lo que ya tienes instalado. Para eso usa `brew upgrade`.
- Si falla algo de `Brewfile`, el setup se detiene.
- Si falla algo de `Brewfile.full`, solo avisa y continúa. Lo más común: no iniciaste sesión en la App Store.

### 4. `zsh`

Clona oh-my-zsh, powerlevel10k y los plugins. Si alguno ya existe, no lo toca. Si tu shell de login no es zsh, te dice cómo cambiarlo. Detalle en [shell](shell.md).

### 5. `dotfiles`

Copia los archivos de `manifest.txt` desde `home/` del repo a tu `$HOME`: configuración de zsh, git, Ghostty, Herdr y VS Code. Ver [Backups](#backups).

### 6. `git`

Guarda tu nombre y email de git en `~/.gitconfig.local`, que `~/.gitconfig` incluye. Así tu identidad nunca entra al repo. Detalle en [git](git.md).

- Si ya existen, no pregunta nada.
- Si no, te los pregunta y propone los de tu `.gitconfig` anterior.
- Con `--yes` usa esos sin preguntar. Si no hay ninguno, avisa y sigue: los agregas después.

### 7. `vscode`

Instala las extensiones de `vscode/extensions.txt` que te falten. Nunca actualiza las que ya tienes. Detalle en [editor](editor.md).

### 8. `claude`

Instala Claude Code con su instalador oficial si no lo tienes. Copia `~/.claude/CLAUDE.md` y `~/.claude/settings.json`, y, si tienes Herdr, reinstala su integración cuando hace falta. Detalle en [Claude Code](claude-code.md).

!!! warning "Reglas personales"
    El `CLAUDE.md` contiene **mis** reglas para Claude Code. Si ya tienes las tuyas, usa `--skip claude`: tu configuración de Claude queda intacta.

## Backups

El setup solo copia los archivos listados en `manifest.txt` y `manifest.claude.txt`, y nunca borra otros. Para cada archivo:

| Si en tu Mac… | El setup… |
|---|---|
| no existe | lo copia |
| es idéntico al del repo | no hace nada |
| es distinto | guarda el tuyo en `~/.dotfiles-backup/<fecha>/` y copia el del repo |

Cada ejecución usa una carpeta nueva (`<fecha>` = `AAAAMMDD-HHMMSS`) que conserva las rutas: `~/.zshrc` queda en `~/.dotfiles-backup/<fecha>/.zshrc`.

### Restaurar

Un archivo:

```bash
cp ~/.dotfiles-backup/20261016-153000/.zshrc ~/.zshrc
```

Todo lo que se respaldó en esa ejecución:

```bash
cp -R ~/.dotfiles-backup/20261016-153000/. ~/
```

Restaurar no desinstala lo que instaló Homebrew. Para eso usa `brew uninstall`.

## Volver a correrlo

Puedes correr `./install.sh` las veces que quieras:

- Lo que ya está instalado se salta.
- Los archivos idénticos no se tocan y no generan backups.
- Tu identidad de git no se vuelve a preguntar.

Para traer cambios del repo: `git pull` y `./install.sh`.

## Omitir pasos

`--skip <paso>` usa el nombre de la lista anterior. Ejemplos:

```bash
./install.sh --skip claude              # conserva tu configuración de Claude Code
./install.sh --skip packages            # solo configuración, sin instalar paquetes
./install.sh --skip vscode --skip git   # varios pasos
```

Un nombre que no existe es un error: el setup se detiene antes de empezar, así un error de dedo no corre todo.

## Después de instalar

El setup no hace esto por ti:

1. **Abre una terminal nueva** (Ghostty) para cargar el shell y el prompt.
2. **Inicia sesión en GitHub:** `gh auth login`.
3. **Inicia sesión en Claude Code:** corre `claude` y sigue las instrucciones.
4. **Llaves SSH:** no se versionan. Créalas o cópialas a mano.
5. **Con `--full`:** si fallaron apps de la App Store, inicia sesión en la App Store y vuelve a correr `./install.sh --full`.
