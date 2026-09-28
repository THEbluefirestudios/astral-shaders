#version 330 compatibility

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

in vec3 vaNormal;
in vec3 vaPosition;

const float LINE_WIDTH = 0.0015;

void main() {
	vec3 linePosStart = mat3(modelViewMatrix) * vaPosition + modelViewMatrix[3].xyz;
	vec3 linePosEnd = mat3(modelViewMatrix) * (vaPosition + vaNormal) + modelViewMatrix[3].xyz;

	vec2 vertexClipCoordStart = vec2(projectionMatrix[0].x, projectionMatrix[1].y) * linePosStart.xy;
	vec2 vertexClipCoordEnd = vec2(projectionMatrix[0].x, projectionMatrix[1].y) * linePosEnd.xy;

	vec2 lineScreenDir = normalize(vertexClipCoordStart / linePosStart.z - vertexClipCoordEnd / linePosEnd.z);
	vec2 lineOffset = vec2(-lineScreenDir.y, lineScreenDir.x) * LINE_WIDTH;

	if (lineOffset.x < 0) lineOffset = -lineOffset;
	if (gl_VertexID % 2 != 0) lineOffset = -lineOffset;

	float vertexViewDepth = linePosStart.z * 0.99609375;
	float vertexClipDepth = projectionMatrix[2].z * vertexViewDepth + projectionMatrix[3].z;

	gl_Position.xyz = vec3(vertexClipCoordStart - lineOffset * (vertexViewDepth * 2.0), vertexClipDepth);
	gl_Position.w = -vertexViewDepth;
}
