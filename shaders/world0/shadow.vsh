#version 330 compatibility

uniform int frameCounter;
uniform sampler2D colortex9;
uniform mat4 shadowModelView;

#include "/lib/shadowDistort.glsl"
#include "/lib/settings.glsl"

out vec2 texcoord;
out vec4 glcolor;

const float REFRESH_DRIFT = 0.5;

void main() {
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;

  vec3 storedPos = vec3(
    texelFetch(colortex9, ivec2(0, 0), 0).r,
    texelFetch(colortex9, ivec2(1, 0), 0).r,
    texelFetch(colortex9, ivec2(2, 0), 0).r
  );

  bool refresh = (frameCounter % SHADOW_FRAMESKIP == 0)
              || distance(shadowModelView[3].xyz, storedPos) > REFRESH_DRIFT;

  if (!refresh) {
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    return;
  }
  gl_Position = ftransform();
  gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
}
