#version 330 compatibility

#include "/lib/shadowDistort.glsl"
#include "/lib/settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

const int shadowMapResolution = 2048;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform float sunAngle;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 ambientColor = vec3(0.25, 0.2, 0.35);
const vec3 sunlightColor = vec3(0.8, 0.75, 0.7);
const vec3 moonlightColor = vec3(0.02, 0.03, 0.05);
const float PI = 3.14159265359;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

vec3 getShadow(vec3 shadowScreenPos){
   vec2 spacing = vec2(SHADOW_BLUR * 2.0 / float(shadowMapResolution));
   vec3 result = vec3(0.0);

   for (int x = -1; x <= 1; x++){
     for (int y = -1; y <= 1; y++){
       vec2 uv = shadowScreenPos.xy + vec2(float(x), float(y)) * spacing;

       float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, uv).r); // sample the shadow map containing everything

       float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, uv).r); // sample the shadow map containing only opaque stuff

       vec4 shadowColor = texture(shadowcolor0, uv);

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
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
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

  vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
 shadowClipPos.z -= 0.001;
 shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
  vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNdcPos * 0.5 + 0.5;

  vec3 shadow = getShadow(shadowScreenPos);
  vec3 blocklight = lightmap.x * blocklightColor;
  vec3 skylight = lightmap.y * skylightColor;
  vec3 ambient = ambientColor;
  vec3 directionalSunlight = sunlightColor * clamp(dot(worldLightVector, normal), 0.0, 1.0) * shadow;
  vec3 flatMoonlight = moonlightColor * lightmap.y;
  vec3 sunlight = mix(flatMoonlight, directionalSunlight, dayFactor);

  color.rgb *= blocklight + (skylight + ambient + sunlight * 0.9) * exposure;
}
