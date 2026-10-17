# Fuentes y colores

## Fuente: IosevkaTerm Nerd Font

Una sola fuente para todo: `font-iosevka-term-nerd-font`, instalada con Homebrew desde `Brewfile` (perfil core).

- **Iosevka Term:** monoespaciada y estrecha; caben más columnas en el mismo ancho.
- **Nerd Font:** agrega miles de iconos (git, carpetas, lenguajes). powerlevel10k los usa en el prompt; sin ellos verías cuadros vacíos.
- **Variante `Mono`:** todos los iconos ocupan una sola columna, así no se desalinean en la terminal.

| Dónde | Nombre de la fuente |
|---|---|
| Ghostty | `IosevkaTerm Nerd Font Mono` |
| VS Code | `IosevkaTerm NFM ExtraLight` (`NFM` = Nerd Font Mono, en su peso más delgado) |

!!! tip "¿La fuente no aparece?"
    Revisa el nombre exacto en *Catálogo Tipográfico* (Font Book). Cada app la busca por un nombre distinto (ver la tabla).

## Colores: Catppuccin Frappé

[Catppuccin](https://catppuccin.com) es una paleta pastel con cuatro variantes: Latte (clara), Frappé, Macchiato y Mocha (la más oscura). Uso **Frappé**, un oscuro de contraste medio, en todas las apps:

| App | Cómo se aplica |
|---|---|
| Ghostty | `theme = Catppuccin Frappe` (incluido en Ghostty) |
| Herdr | `theme.name = "catppuccin"` |
| VS Code | Extensiones `catppuccin-vsc` y `catppuccin-vsc-icons`. Con macOS en modo claro cambia a Latte |
| Prompt | Estilo Pure de powerlevel10k: usa los colores de la terminal, así que hereda Frappé de Ghostty |

Colores principales de Frappé:

| Color | Hex | Uso típico |
|---|---|---|
| <span class="swatch" style="background: #303446"></span> Base | `#303446` | Fondo |
| <span class="swatch" style="background: #292c3c"></span> Mantle | `#292c3c` | Paneles y barras |
| <span class="swatch" style="background: #c6d0f5"></span> Text | `#c6d0f5` | Texto |
| <span class="swatch" style="background: #ca9ee6"></span> Mauve | `#ca9ee6` | Acento |
| <span class="swatch" style="background: #8caaee"></span> Blue | `#8caaee` | Links, funciones |
| <span class="swatch" style="background: #a6d189"></span> Green | `#a6d189` | Strings, éxito |
| <span class="swatch" style="background: #ef9f76"></span> Peach | `#ef9f76` | Números |
| <span class="swatch" style="background: #e5c890"></span> Yellow | `#e5c890` | Avisos |
| <span class="swatch" style="background: #e78284"></span> Red | `#e78284` | Errores |

Para cambiar de variante, edita esas claves en los archivos de `home/`. Detalles en [terminal](terminal.md) y [editor](editor.md).
