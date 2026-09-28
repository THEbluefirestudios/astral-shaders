#version 330 compatibility

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightLevelData;
layout(location = 2) out vec4 encodedNormal;

void main() {
	color = vec4(0.0, 0.0, 0.0, 0.5);
	lightLevelData = vec4(0.0, 0.0, 0.0, 1.0);
	encodedNormal = vec4(0.5, 1.0, 0.5, 1.0);
}
