# Terminal

La terminal es **Ghostty** con **Herdr** encima. Las dos se instalan desde `Brewfile` (perfil core) y su configuración la copia el paso `dotfiles`.

## Ghostty

```ini title="~/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
font-family = "IosevkaTerm Nerd Font Mono"
theme = Catppuccin Frappe
window-padding-x = 10
window-padding-y = 10
window-padding-balance = true
```

| Opción | Valor | Efecto |
|---|---|---|
| `font-family` | `IosevkaTerm Nerd Font Mono` | Fuente monoespaciada con los glifos que usa el prompt. Ver [fuentes y colores](fonts-and-colors.md) |
| `theme` | `Catppuccin Frappe` | Tema incluido en Ghostty; no hay que instalar nada |
| `window-padding-x` / `-y` | `10` | Margen interno de la ventana, en puntos |
| `window-padding-balance` | `true` | Reparte el espacio sobrante para que el texto quede centrado |

!!! tip "Editar, recargar y validar"
    - El alias `ghosttyc` abre el archivo en VS Code.
    - <kbd>⌘</kbd><kbd>⇧</kbd><kbd>,</kbd> recarga la configuración sin cerrar Ghostty.
    - `ghostty +validate-config` revisa que no haya errores. Los tests del repo lo corren si Ghostty está instalado.

Solo se versiona `config.ghostty`. La carpeta `auto/`, que escribe el selector de temas de Ghostty, queda fuera del repo.

## Herdr

[Herdr](https://herdr.dev) es un multiplexor de agentes: corre varias sesiones de agentes (como Claude Code) dentro de la terminal y muestra el estado de cada una.

```toml title="~/.config/herdr/config.toml"
onboarding = false

[ui.toast]
delivery = "terminal"

[ui.sound]
enabled = true

[ui]
status_indicators = "symbols"

[theme]
name = "catppuccin"
auto_switch = false
```

| Opción | Valor | Efecto |
|---|---|---|
| `onboarding` | `false` | No muestra el asistente de bienvenida |
| `ui.toast.delivery` | `"terminal"` | Las notificaciones salen como avisos de la terminal |
| `ui.sound.enabled` | `true` | Sonido cuando un agente cambia de estado |
| `ui.status_indicators` | `"symbols"` | Estado de cada agente con símbolos |
| `theme.name` | `"catppuccin"` | Mismo tema que Ghostty y VS Code |
| `theme.auto_switch` | `false` | No cambia de tema con el modo claro/oscuro de macOS |

Solo se versiona `config.toml`. Los archivos que Herdr genera al correr (logs, sockets, `session.json`) nunca entran al repo.

La integración con Claude Code (un hook en `~/.claude/settings.json`) la instala el paso `claude`. Ver [Claude Code](claude-code.md#herdr).
