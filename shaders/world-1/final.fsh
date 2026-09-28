#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/fxaa.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

layout(location = 0) out vec4 color;


vec3 myColorGrade(vec3 col) {
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, GRADE_SATURATION);

	col = pow(col, vec3(GRADE_SHADOW_LIFT));

	vec3 blueTint = vec3(0.085, 0.03, 0.03);   // was gna make this blue... didnt hit the dreamy feel i was going for so i made it purple
	col += blueTint;						 // aint changing the var name tho

	col = col * 1.08 - 0.015;

	return clamp(col, 0.0, 1.0);
}

void main() {
  vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
  color = vec4(applyFXAA(colortex0, texcoord, texelSize), 1.0);
  color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
#if BLOOM_ENABLED == 1
  color.rgb += texture(colortex4, texcoord).rgb * BLOOM_INTENSITY;
#endif

  color.rgb = myColorGrade(color.rgb);
}