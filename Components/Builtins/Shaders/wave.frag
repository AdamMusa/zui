#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 resolution;
    float frequency;
    float amplitude;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 uv = qt_TexCoord0;
    float aspect = resolution.y > 0.0 ? resolution.x / resolution.y : 1.0;
    uv.x += sin((uv.y * frequency * 6.2831853) + time) * amplitude / max(aspect, 0.001);
    fragColor = texture(source, uv) * qt_Opacity;
}
