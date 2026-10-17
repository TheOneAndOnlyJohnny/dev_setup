# Apps y paquetes

Todo se instala con `brew bundle` (paso `packages`) desde dos archivos:

| Archivo | Cuándo | Si algo falla |
|---|---|---|
| `Brewfile` | Siempre | El setup se detiene |
| `Brewfile.full` | Con `--full` | Avisa y continúa |

El setup nunca actualiza lo que ya tienes instalado. Para actualizar: `brew upgrade` (o el alias `bu`).

## Core (`Brewfile`)

| Paquete | Tipo | Para qué |
|---|---|---|
| `git`, `gh` | CLI | Git y la CLI de GitHub |
| `node`, `bun` | CLI | JavaScript/TypeScript |
| `go` | CLI | Go (`GOPATH=~/go`) |
| `php` | CLI | PHP |
| `dbmate` | CLI | Migraciones de base de datos, independiente del framework |
| `mkcert` | CLI | Certificados HTTPS de confianza para desarrollo local |
| `mysql-client` | CLI | `mysql` y `mysqldump`. Es *keg-only*: `starter.sh` lo agrega al `PATH` |
| `bats-core`, `shellcheck` | CLI | Tests y lint de este repo |
| `ghostty` | App | Terminal. Ver [terminal](terminal.md) |
| `herdr` | CLI | Multiplexor de agentes. Ver [terminal](terminal.md#herdr) |
| `visual-studio-code` | App | Editor. Ver [editor](editor.md) |
| `orbstack` | App | Docker y máquinas Linux. Incluye `docker` y `docker compose` |
| `font-iosevka-term-nerd-font` | Fuente | Ver [fuentes y colores](fonts-and-colors.md) |

!!! note "Claude Code no está aquí"
    Lo instala el paso `claude` con el instalador oficial, que se actualiza solo. Ver [Claude Code](claude-code.md).

## Full (`Brewfile.full`)

Apps personales. Solo se instalan con `--full`.

!!! warning "App Store"
    Las apps de la App Store se instalan con `mas` y necesitan que hayas iniciado sesión en la App Store **antes** de correr el setup. Si no, esas apps fallan, el setup avisa y sigue.

| Paquete | Tipo | Para qué |
|---|---|---|
| `diceware` | CLI | Frases de contraseña fáciles de recordar |
| `dnsmasq` | CLI | DNS local (p. ej. dominios `.test` para desarrollo) |
| `mkdocs` | CLI | Sitios de documentación en Markdown |
| `pinentry-mac` | CLI | Diálogo de macOS para la contraseña de GPG |
| `speedtest` | CLI | Prueba de velocidad de Ookla (tap `teamookla/speedtest`) |
| `mas` | CLI | Instala apps de la App Store desde la terminal |
| `claude` | App | App de escritorio de Claude |
| `cleanupbuddy` | App | Bloquea teclado y trackpad mientras los limpias |
| `macpacker` | App | Gestor de archivos comprimidos |
| `raycast` | App | Lanzador (reemplazo de Spotlight) |
| `surfshark` | App | VPN |
| `thorium` | App | Lector de libros EPUB |
| `transmission` | App | Cliente BitTorrent |
| `transmit` | App | Cliente FTP/SFTP/S3 |
| `vorssaint` | App | Barra de menús: mantener despierta la Mac, monitor del sistema, mezclador de volumen |
| `whatsapp` | App | WhatsApp |
| Bear | App Store | Notas en Markdown |
| Klack | App Store | Sonido de teclado mecánico al escribir |
| Pixelmator Pro | App Store | Edición de imágenes |
| Tailscale | App Store | VPN entre tus dispositivos |
| The Unarchiver | App Store | Descompresor de archivos |

## Agregar o quitar algo

1. Edita `Brewfile` (si lo necesita cualquier entorno de desarrollo) o `Brewfile.full` (si es una app personal).
2. Usa `brew "nombre"` para CLIs, `cask "nombre"` para apps y fuentes, y `mas "Nombre", id: 123` para la App Store (el ID sale de `mas search`).
3. Corre `./install.sh` (o `brew bundle --file=Brewfile`) para instalarlo.

!!! info "Quitar no desinstala"
    Borrar una línea del Brewfile no desinstala el paquete. Hazlo tú con `brew uninstall <nombre>`.
