#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float amount;
    vec2 resolution;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    float pixels = max(amount, 1.0);
    vec2 cells = max(resolution / pixels, vec2(1.0));
    vec2 uv = (floor(qt_TexCoord0 * cells) + vec2(0.5)) / cells;
    fragColor = texture(source, uv) * qt_Opacity;
}
