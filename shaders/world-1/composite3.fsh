#version 330 compatibility

#include "/lib/settings.glsl"

uniform sampler2D colortex4;

uniform float viewWidth;

in vec2 texcoord;

/* RENDERTARGETS: 3,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bloomHorizontal;

const int BLOOM_RADIUS = 8;

void main() {
  vec3 bsum = vec3(0.0);
  float bweight = 0.0;
  float sigma = max(BLOOM_SPREAD * 4.0, 0.5);
  vec2 bstep = vec2(1.0 / viewWidth, 0.0);

  for (int i = -BLOOM_RADIUS; i <= BLOOM_RADIUS; i++) {
    float w = exp(-(float(i * i)) / (2.0 * sigma * sigma));
    bsum += texture(colortex4, texcoord + bstep * float(i)).rgb * w;
    bweight += w;
  }

  bloomHorizontal = vec4(bsum / bweight, 1.0);

  color = vec4(0.0, 0.0, 0.0, 1.0);
}
