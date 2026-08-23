#version 440

// Qt 6 / QSB port for Omarchy UI. Original attribution and license follow.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 qt_FragColor;
layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  float time;
  vec2 resolution;
  vec2 mouse;
  float intensity;
  float frequency;
  float amount;
  float amplitude;
};

#define iTime (time * max(0.15, frequency * 0.32))
#define iResolution vec3(resolution, 1.0)
#define iMouse vec4(mouse, 0.0, 0.0)

// Title:  Hexagon Plasma
// Author: Nemerix
// URL:    https://www.shadertoy.com/view/3fy3z3
// Date:   26-May-2025
// Desc:   Heavily inspired by https://www.shadertoy.com/view/WfS3Dd
//
// I put this together after poking at it for a few hours, to make sure I actually learned something from it. :D

// Shader by Nemerix, 2025-05-26.
// Code made available under the MIT license.

float sqr(float x) { return x*x; }

float hexSdf(in vec2 pos)
{
    return max(max(abs(dot(pos, vec2(0,2))), abs(dot(pos, vec2(1.732,1)))), abs(dot(pos, vec2(1.732,-1))));
}

float smoothSdf(in vec2 pos)
{
    return mix(sqr(hexSdf(pos)), dot(pos, pos), smoothstep(0.8, 1.5, dot(pos, pos)));
}

float sfield(in vec2 s)
{
    return s.x * s.y;
}

vec3 cmap(in vec2 pos)
{
    return mix(vec3(0.1,0.6,0.8), vec3(0.5), 0.7 * tanh(dot(pos, pos)));
}

const mat2 R = mat2(0.6, 0.8, -0.8, 0.6);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float d = smoothSdf(uv) - 1.0;
    d = sqrt(abs(d));

    vec2 samp = uv * d;
    float y = 0.0;
    float scale = 1.0;

    for (int i = 0; i < 4; ++i)
    {
        samp = sin(R * samp * hexSdf(samp) + vec2(iTime));
        y += scale * sfield(samp);
        scale *= 0.75;
    }

    vec3 col = cmap(uv) / abs(y);
    col = tanh(0.1 * col);
    fragColor = vec4(col, 1);
}

void main()
{
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * resolution;
  vec4 shaderColor = vec4(0.0);
  mainImage(shaderColor, fragCoord);
  float exposure = mix(0.68, 1.32, clamp(intensity, 0.0, 1.0));
  float contrast = mix(0.72, 1.35, clamp(amount / 40.0, 0.0, 1.0));
  vec3 graded = (shaderColor.rgb - 0.5) * contrast + 0.5;
  graded *= mix(0.85, 1.35, clamp(amplitude / 0.16, 0.0, 1.0));
  qt_FragColor = vec4(max(vec3(0.0), graded * exposure), shaderColor.a) * qt_Opacity;
}
