#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

/*
const int colortex0Format = RGB16;
*/

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 ambientColor = vec3(0.1);

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  vec2 lightmap = texture(colortex1, texcoord).xy;

  color = texture(colortex0, texcoord);
   color.rgb = pow(color.rgb, vec3(2.2));

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return; // let's skip whats beneath us - the lighting apply logic!
    }

  vec3 blocklight = lightmap.x * blocklightColor;
  vec3 skylight = lightmap.y * skylightColor;
  vec3 ambient = ambientColor;

  color.rgb *= blocklight + skylight + ambient;
}
