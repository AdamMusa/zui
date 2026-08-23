#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float amount;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec4 pixel = texture(source, qt_TexCoord0);
    float luminance = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor = vec4(mix(pixel.rgb, vec3(luminance), clamp(amount, 0.0, 1.0)), pixel.a) * qt_Opacity;
}
