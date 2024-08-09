#version 330 core

uniform mat4 u_projTrans;
uniform mat4 u_modelTrans;

in vec3 a_position;
in vec2 a_texCoord0;

out vec2 v_texCoord;

void main() {
    v_texCoord = a_texCoord0;
    gl_Position = u_projTrans * u_modelTrans * vec4(a_position, 1.0);
}
