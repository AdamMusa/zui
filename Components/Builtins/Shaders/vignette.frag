#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float intensity;
    float radius;
    vec4 color;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec4 pixel = texture(source, qt_TexCoord0);
    float distanceFromCenter = length(qt_TexCoord0 - vec2(0.5));
    float edge = smoothstep(max(radius, 0.001), max(radius, 0.001) + 0.35, distanceFromCenter);
    pixel.rgb = mix(pixel.rgb, color.rgb, clamp(edge * intensity, 0.0, 1.0));
    fragColor = pixel * qt_Opacity;
}
