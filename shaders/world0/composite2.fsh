#version 330 compatibility

#include "/lib/shadowDistort.glsl"
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D colortex2;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

in vec2 texcoord;

/* RENDERTARGETS: 3,4 */
layout(location = 0) out vec4 godrayMask;
layout(location = 1) out vec4 brightColor;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

void main() {
  vec3 col = texture(colortex0, texcoord).rgb;
  float depth = texture(depthtex0, texcoord).r;

  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 rawNormal = (encodedNormal - 0.5) * 2.0;
  bool isCloud = dot(rawNormal, rawNormal) < 0.5;
  bool isSky = depth >= 0.9999;

  float brightness = max(col.r, max(col.g, col.b));
  float excess = (isSky || isCloud) ? 0.0 : max(brightness - BLOOM_THRESHOLD, 0.0);
  brightColor = vec4(col * excess, 1.0);
  
  if (depth >= 0.9999) {
    godrayMask = vec4(1.0);
    return;
  }

  vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
  vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNdcPos * 0.5 + 0.5;

  float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);

  if (transparentShadow == 1.0) {
    godrayMask = vec4(1.0);
    return;
  }

  float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);

  if (opaqueShadow == 0.0) {
    vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
    godrayMask = vec4(shadowColor.rgb * (1.0 - shadowColor.a), 1.0);
  } else {
    godrayMask = vec4(0.0, 0.0, 0.0, 1.0);
  }
}