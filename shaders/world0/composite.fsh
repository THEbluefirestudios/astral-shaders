#version 330 compatibility

#include "/lib/shadowDistort.glsl"
#include "/lib/settings.glsl"


uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

uniform sampler2D colortex6;
uniform sampler2D colortex8;
uniform sampler2D colortex7;

uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
/*
const int colortex0Format = RGB16;
*/

const int shadowMapResolution = 2048;
const float shadowIntervalSize = 8.0;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform float sunAngle;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 sunlightColor = vec3(1.0);
const vec3 moonlightColor = vec3(0.02, 0.03, 0.05);
const vec3 ambientColor = vec3(0.1);
const float PI = 3.14159265359;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}


vec3 getShadow(vec3 shadowScreenPos){
   vec2 texel = vec2(1.0 / float(shadowMapResolution));
   vec2 f = fract(shadowScreenPos.xy * float(shadowMapResolution));
   vec2 base = shadowScreenPos.xy - f * texel;
   vec2 spacing = vec2(SHADOW_BLUR * 2.0 / float(shadowMapResolution));
   vec3 result = vec3(0.0);

   for (int x = -1; x <= 1; x++){
     for (int y = -1; y <= 1; y++){
       vec2 uv = base + vec2(float(x), float(y)) * spacing;

       float d00 = texture(colortex6, uv).r;
       float d10 = texture(colortex6, uv + vec2(texel.x, 0.0)).r;
       float d01 = texture(colortex6, uv + vec2(0.0, texel.y)).r;
       float d11 = texture(colortex6, uv + texel).r;
       float transparentShadow = step(shadowScreenPos.z, mix(mix(d00, d10, f.x), mix(d01, d11, f.x), f.y));

       float e00 = texture(colortex7, uv).r;
       float e10 = texture(colortex7, uv + vec2(texel.x, 0.0)).r;
       float e01 = texture(colortex7, uv + vec2(0.0, texel.y)).r;
       float e11 = texture(colortex7, uv + texel).r;
       float opaqueShadow = step(shadowScreenPos.z, mix(mix(e00, e10, f.x), mix(e01, e11, f.x), f.y));

       vec4 shadowColor = texture(colortex8, uv);

       if (transparentShadow == 1.0){
         result += vec3(1.0);
       } else if (opaqueShadow == 0.0){
         result += vec3(0.0);
       } else {
         result += shadowColor.rgb * (1.0 - shadowColor.a) * 3;
       }
     }
   }

   return result / 9.0;
 }

void main() {
  vec2 lightmap = texture(colortex1, texcoord).xy;
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 rawNormal = (encodedNormal - 0.5) * 2.0;
  bool isCloud = dot(rawNormal, rawNormal) < 0.5;
  vec3 normal = isCloud ? vec3(0.0, 1.0, 0.0) : normalize(rawNormal);
  vec3 lightVector = normalize(shadowLightPosition);
  vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

  float sunHeight = sin(sunAngle * 2.0 * PI);
  float dayFactor = smoothstep(-0.1, 0.1, sunHeight);

  float exposure = sunHeight < 0.0
    ? mix(EXPOSURE_MIDNIGHT, EXPOSURE_SUNRISE, dayFactor)
    : mix(EXPOSURE_SUNRISE, EXPOSURE_NOON, smoothstep(0.0, 1.0, sunHeight));

  color = texture(colortex0, texcoord);
   color.rgb = pow(color.rgb, vec3(2.2));

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }

  vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0; // normalized device coordinates (NDC); [-1.0, 1.0]
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos); // position in view space
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz; // position relative to the feet of the player
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
 shadowClipPos.z -= 0.001;
 shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
  vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNdcPos * 0.5 + 0.5;

  vec3 shadow = getShadow(shadowScreenPos);
  if (isCloud) {
    shadow = vec3(1.0);
  }
  vec3 blocklight = lightmap.x * blocklightColor;
  vec3 skylight = lightmap.y * skylightColor * mix(0.05, 1.0, dayFactor);
  vec3 ambient = mix(vec3(0.01), ambientColor, dayFactor);
  vec3 directionalSunlight = sunlightColor * clamp(dot(worldLightVector, normal), 0.0, 1.0) * shadow;
  vec3 flatMoonlight = moonlightColor * lightmap.y;
  vec3 sunlight = mix(flatMoonlight, directionalSunlight, dayFactor);
  if (isCloud) {
    sunlight = sunlightColor;
  }

  color.rgb *= blocklight + (skylight + ambient + sunlight) * exposure;
}