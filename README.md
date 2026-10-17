# dev_setup

Mi entorno de desarrollo para macOS (Apple Silicon), documentado pieza por pieza y reproducible con un solo script.

📖 **Documentación completa: https://theoneandonlyjohnny.github.io/dev_setup/**

## Qué incluye

- **Terminal:** Ghostty + Herdr (multiplexor de agentes).
- **Shell:** zsh, oh-my-zsh, plugins y prompt powerlevel10k, más mis aliases y funciones.
- **Editor:** VS Code con sus extensiones y `settings.json`.
- **Fuente y tema:** IosevkaTerm Nerd Font y Catppuccin Frappé en todas las apps.
- **Herramientas:** git, gh, node, bun, go, php, OrbStack (Docker) y más, vía Homebrew. Con `--full`, también mis apps personales.
- **Claude Code:** con mis reglas globales (`CLAUDE.md`) y un `settings.json` limpio.

No cambia preferencias de macOS ni versiona secretos. Antes de reemplazar un archivo tuyo, guarda una copia en `~/.dotfiles-backup/`.

## Instalación rápida

Requiere una Mac con Apple Silicon y tu usuario normal (sin `sudo`).

```bash
git clone https://github.com/theoneandonlyjohnny/dev_setup.git
cd dev_setup
./install.sh --dry-run   # muestra qué haría, sin cambiar nada
./install.sh             # instala (--full para las apps personales)
```

Opciones, qué hace cada paso y cómo restaurar backups: [guía de instalación](docs/install.md).

## Documentación

Las mismas páginas del sitio, en [`docs/`](docs/):

| Página | Tema |
|---|---|
| [Inicio](docs/index.md) | Todo el setup de un vistazo y cómo encaja |
| [Instalación](docs/install.md) | Requisitos, opciones, pasos, backups |
| [Apps y paquetes](docs/apps.md) · [Shell](docs/shell.md) · [Terminal](docs/terminal.md) · [Editor](docs/editor.md) · [Fuentes y colores](docs/fonts-and-colors.md) · [Git](docs/git.md) · [Claude Code](docs/claude-code.md) | Cada pieza en detalle |
| [Cómo funciona el repo](docs/repository.md) | Estructura, cómo agregar cosas, tests y cómo publicar el sitio |
