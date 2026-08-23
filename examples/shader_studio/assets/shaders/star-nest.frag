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

// Title:  Star Nest
// Author: Kali
// URL:    https://www.shadertoy.com/view/XlfGRj
// Date:   16-Jun-2013
// Desc:   3D kaliset fractal - volumetric rendering and some tricks. I put the params on top to play with. Mouse enabled to explore different regions.

// Star Nest by Pablo Roman Andrioli
// License: MIT

#define iterations 17
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

#define zoom   0.800
#define tile   0.850
#define speed  0.010

#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	//get coords and direction
	vec2 uv=fragCoord.xy/iResolution.xy-.5;
	uv.y*=iResolution.y/iResolution.x;
	vec3 dir=vec3(uv*zoom,1.);
	float time=iTime*speed+.25;

	//mouse rotation
	float a1=.5+iMouse.x/iResolution.x*2.;
	float a2=.8+iMouse.y/iResolution.y*2.;
	mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
	mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
	dir.xz*=rot1;
	dir.xy*=rot2;
	vec3 from=vec3(1.,.5,0.5);
	from+=vec3(time*2.,time,-2.);
	from.xz*=rot1;
	from.xy*=rot2;

	//volumetric rendering
	float s=0.1,fade=1.;
	vec3 v=vec3(0.);
	for (int r=0; r<volsteps; r++) {
		vec3 p=from+s*dir*.5;
		p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
		float pa,a=pa=0.;
		for (int i=0; i<iterations; i++) {
			p=abs(p)/dot(p,p)-formuparam; // the magic formula
			a+=abs(length(p)-pa); // absolute sum of average change
			pa=length(p);
		}
		float dm=max(0.,darkmatter-a*a*.001); //dark matter
		a*=a*a; // add contrast
		if (r>6) fade*=1.-dm; // dark matter, don't render near
		//v+=vec3(dm,dm*.5,0.);
		v+=fade;
		v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
		fade*=distfading; // distance fading
		s+=stepsize;
	}
	v=mix(vec3(length(v)),v,saturation); //color adjust
	fragColor = vec4(v*.01,1.);

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
