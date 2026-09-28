#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;


uniform vec3 fogColor;
uniform float far;
uniform int isEyeInWater;


in vec2 texcoord;

const float FOG_DENSITY = 5.0;
const float WATER_FOG_DENSITY = 0.015;
const vec3 WATER_FOG_COLOR = vec3(0.0, 0.2, 0.9);
const vec3 WATER_TINT = vec3(0.6, 0.8, 1.0);

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  if (isEyeInWater == 1) {
    color.rgb *= WATER_TINT;
  }

  float depth = texture(depthtex0, texcoord).r;
  if (depth == 1.0){
    return;
  }

  vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);


  if (isEyeInWater == 1) {
    float waterDist = length(viewPos);
    float waterFogFactor = 1.0 - exp(-waterDist * WATER_FOG_DENSITY);
    color.rgb = mix(color.rgb, WATER_FOG_COLOR, waterFogFactor);
  } else {
    float dist = length(viewPos) / far;
    float fogFactor = exp(-FOG_DENSITY * (1.0 - dist));
    vec3 tintedFog = pow(fogColor, vec3(2.2)) * vec3(0.9, 0.8, 1.0);
    color.rgb = mix(color.rgb, tintedFog, clamp(fogFactor, 0.0, 1.0));
  }
}