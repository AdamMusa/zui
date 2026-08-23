# Lumen Forge

A live GPU shader laboratory whose application surface is written entirely in Ruby. Its library is
made entirely of substantial Shadertoy works compiled for Qt 6's GPU pipeline: a procedural ocean,
volumetric star nest, hex plasma, synthwave city, and the Golden Apollian tunnel. Speed, exposure,
energy, contrast, and pointer/camera uniforms are reactive from Ruby.

The default effect is **Golden Apollian** by mrange, ported from
[Shadertoy WlcfRS](https://www.shadertoy.com/view/WlcfRS) to Qt 6 QSB. The author explicitly
released the shader under CC0; its attribution and license declaration remain in the source file.
Every library entry retains its author, original Shadertoy URL, and license in the shader header and
in [`assets/shaders/README.md`](assets/shaders/README.md).

```bash
zui run main.rb
```
