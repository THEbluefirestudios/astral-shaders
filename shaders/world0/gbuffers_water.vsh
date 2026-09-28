#version 330 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;

#include "/lib/settings.glsl"

attribute vec4 mc_Entity;

void main() {
	vec4 position = gl_Vertex;

	if (mc_Entity.x == 10002.0) {
		vec2 p = (gbufferModelViewInverse * vec4(position.xyz, 1.0)).xz;
		float t = frameTimeCounter;

		float wave =
			  sin(dot(p, vec2( 0.71,  0.70)) * 0.45 + t * 1.30) * 1.00
			+ sin(dot(p, vec2(-0.42,  0.91)) * 1.05 - t * 1.90) * 0.55
			+ sin(dot(p, vec2( 0.96, -0.28)) * 1.90 + t * 2.70) * 0.30
			+ sin(dot(p, vec2(-0.83, -0.56)) * 3.40 - t * 3.60) * 0.15;

		position.y += wave * WATER_WAVE_STRENGTH;
	}

	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * position;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;
}
