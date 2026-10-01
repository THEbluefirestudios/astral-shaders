#version 330 compatibility

#include "/lib/settings.glsl"

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform mat4 shadowModelView;
uniform int frameCounter;

in vec2 texcoord;

/* RENDERTARGETS: 6,7,8,9 */
layout(location = 0) out vec4 shadow0Cache;
layout(location = 1) out vec4 shadow1Cache;
layout(location = 2) out vec4 shadowColorCache;
layout(location = 3) out vec4 refreshState;

/*
const int colortex6Format = R32F;
const int colortex7Format = R32F;
const int colortex8Format = RGBA16;
const int colortex9Format = R32F;
const bool colortex6Clear = false;
const bool colortex7Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;
*/

const float REFRESH_DRIFT = 0.5;

void main() {
  vec3 storedPos = vec3(
    texelFetch(colortex9, ivec2(0, 0), 0).r,
    texelFetch(colortex9, ivec2(1, 0), 0).r,
    texelFetch(colortex9, ivec2(2, 0), 0).r
  );

  bool refresh = (frameCounter % SHADOW_FRAMESKIP == 0)
              || distance(shadowModelView[3].xyz, storedPos) > REFRESH_DRIFT;

  if (refresh) {
    shadow0Cache = vec4(texture(shadowtex0, texcoord).r, 0.0, 0.0, 1.0);
    shadow1Cache = vec4(texture(shadowtex1, texcoord).r, 0.0, 0.0, 1.0);
    shadowColorCache = texture(shadowcolor0, texcoord);
  } else {
    shadow0Cache = texture(colortex6, texcoord);
    shadow1Cache = texture(colortex7, texcoord);
    shadowColorCache = texture(colortex8, texcoord);
  }

  ivec2 pix = ivec2(gl_FragCoord.xy);
  if (pix == ivec2(0, 0)) {
    refreshState = refresh ? vec4(shadowModelView[3].x, 0.0, 0.0, 1.0) : vec4(storedPos.x, 0.0, 0.0, 1.0);
  } else if (pix == ivec2(1, 0)) {
    refreshState = refresh ? vec4(shadowModelView[3].y, 0.0, 0.0, 1.0) : vec4(storedPos.y, 0.0, 0.0, 1.0);
  } else if (pix == ivec2(2, 0)) {
    refreshState = refresh ? vec4(shadowModelView[3].z, 0.0, 0.0, 1.0) : vec4(storedPos.z, 0.0, 0.0, 1.0);
  } else {
    refreshState = vec4(0.0, 0.0, 0.0, 1.0);
  }
}
