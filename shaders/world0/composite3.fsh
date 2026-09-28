#version 330 compatibility

#include "/lib/settings.glsl"

uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex1;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferProjection;
uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;
uniform int isEyeInWater;

in vec2 texcoord;

/* RENDERTARGETS: 3,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bloomHorizontal;

const int BLOOM_RADIUS = 8;

#ifndef GODRAY_USE_SKYLIGHT_FALLBACK
#define GODRAY_USE_SKYLIGHT_FALLBACK 1
#endif

const float PI = 3.14159265359;

float getSkylightDayFactor() {
  float maxSkylight = 0.0;
  vec2 offset = 6.0 / vec2(viewWidth, viewHeight);

  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 uv = texcoord + vec2(float(x), float(y)) * offset;
      maxSkylight = max(maxSkylight, texture(colortex1, uv).y);
    }
  }

  return smoothstep(0.15, 0.6, maxSkylight);
}

float getGodrayBrightness() {
  float sunHeight = sin(sunAngle * 2.0 * PI);
  float angleFactor = smoothstep(-0.1, 0.1, sunHeight);

#if GODRAY_USE_SKYLIGHT_FALLBACK == 1
  float lightFactor = getSkylightDayFactor();
  float combined = min(angleFactor, lightFactor);
#else
  float combined = angleFactor;
#endif

  return mix(GODRAY_NIGHT_INTENSITY, 1.0, combined);
}

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

  if (isEyeInWater == 1) {
    color = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  float brightness = getGodrayBrightness();

  if (brightness <= 0.0) {
    color = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  vec3 lightViewPos = normalize(shadowLightPosition);
  vec4 lightClipPos = gbufferProjection * vec4(lightViewPos * 100.0, 1.0);
  vec2 lightScreenPos = (lightClipPos.xy / lightClipPos.w) * 0.5 + 0.5;

  vec3 viewDir = vec3(0.0, 0.0, -1.0);
  float lightFacing = dot(lightViewPos, viewDir);
  float edgeFade = smoothstep(-0.1, 0.3, lightFacing);

  float distToLeft = lightScreenPos.x;
  float distToRight = 1.0 - lightScreenPos.x;
  float distToBottom = lightScreenPos.y;
  float distToTop = 1.0 - lightScreenPos.y;
  float nearestEdge = min(min(distToLeft, distToRight), min(distToBottom, distToTop));

  edgeFade *= smoothstep(0.0, GODRAY_EDGE_FADE, nearestEdge);

  if (edgeFade <= 0.0) {
    color = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  vec2 toLight = texcoord - lightScreenPos;
  vec2 dir = normalize(toLight);

  vec2 perp = vec2(-dir.y, dir.x) * GODRAY_NORMAL_BLUR / vec2(viewWidth, viewHeight);

  vec2 stepCoord = toLight * GODRAY_DENSITY / float(GODRAY_SAMPLES);

  vec2 sampleCoord = texcoord;
  float illuminationDecay = 1.0;
  vec3 result = vec3(0.0);

  for (int i = 0; i < GODRAY_SAMPLES; i++) {
    sampleCoord -= stepCoord;

    vec3 tap = texture(colortex3, sampleCoord).rgb;
    tap += texture(colortex3, sampleCoord + perp).rgb;
    tap += texture(colortex3, sampleCoord - perp).rgb;

    result += tap * illuminationDecay;
    illuminationDecay *= GODRAY_DECAY;
  }

  result /= float(GODRAY_SAMPLES) * 3.0;

  float distFalloff = 1.0 / (1.0 + length(toLight) * GODRAY_FALLOFF);

  color = vec4(result * edgeFade * distFalloff * brightness, 1.0);
}