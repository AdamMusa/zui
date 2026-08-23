# Shader provenance

The five effects are Qt 6 / Vulkan-QSB ports of complete Shadertoy works, not color-filter presets:

- **Golden Apollian**, mrange — https://www.shadertoy.com/view/WlcfRS — CC0
- **Very fast procedural ocean**, afl_ext — https://www.shadertoy.com/view/MdXyzX — MIT
- **Star Nest**, Kali / Pablo Roman Andrioli — https://www.shadertoy.com/view/XlfGRj — MIT
- **Hexagon Plasma**, Nemerix — https://www.shadertoy.com/view/3fy3z3 — MIT
- **Synthwave City**, 3w36zj6, based on Jan Mróz's original — https://www.shadertoy.com/view/7lKyDD — CC BY 3.0

Sources were retrieved from the XScreenSaver source mirror, which preserves their attribution and
license headers. Port changes are limited to the Qt uniform block and entry point, cursor and
time/speed mappings, exposure/energy/contrast controls, coordinate orientation, and window opacity.
Each `.frag.qsb` is compiled from its neighboring `.frag` source using Qt Shader Baker.
