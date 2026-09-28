#version 330 compatibility

#include "/lib/settings.glsl"

uniform sampler2D colortex5;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 4 */
layout(location = 0) out vec4 color;

const int BLOOM_RADIUS = 8;

void main() {
  vec3 sum = vec3(0.0);
  float totalWeight = 0.0;
  float sigma = max(BLOOM_SPREAD * 4.0, 0.5);
  vec2 stepCoord = vec2(0.0, 1.0 / viewHeight);

  for (int i = -BLOOM_RADIUS; i <= BLOOM_RADIUS; i++) {
    float weight = exp(-(float(i * i)) / (2.0 * sigma * sigma));
    sum += texture(colortex5, texcoord + stepCoord * float(i)).rgb * weight;
    totalWeight += weight;
  }

  color = vec4(sum / totalWeight, 1.0);
}