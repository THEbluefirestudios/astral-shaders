#version 330 compatibility

uniform sampler2D gtexture;

uniform int renderStage;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
  if (renderStage == MC_RENDER_STAGE_HAND_SOLID || renderStage == MC_RENDER_STAGE_HAND_TRANSLUCENT) {
    discard;
  }

  if (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) {
    discard;
  }

  color = texture(gtexture, texcoord) * glcolor;
  if (color.a < 0.1){
    discard;
  }
}