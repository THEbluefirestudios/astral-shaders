#version 330 compatibility

#include "/lib/settings.glsl"

uniform sampler2D colortex0;\
uniform sampler2D depthtex0;

in vec2 texcoord;

/* RENDERTARGETS: 3,4 */
layout(location = 0) out vec4 godrayMask;
layout(location = 1) out vec4 brightColor;

void main() {
  vec3 col = texture(colortex0, texcoord).rgb;
  float brightness = max(col.r, max(col.g, col.b));
  float excess = isSky ? 0.0 : max(brightness - BLOOM_THRESHOLD, 0.0);
  brightColor = vec4(col * excess, 1.0);

  godrayMask = vec4(0.0, 0.0, 0.0, 1.0);
}
