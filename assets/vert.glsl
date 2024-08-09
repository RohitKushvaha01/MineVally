#version 330 core
attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_texCoord0;

uniform mat4 u_projTrans;

varying vec3 v_normal;
varying vec2 v_texCoord;

void main() {
    v_normal = a_normal;
    v_texCoord = a_texCoord0;
    gl_Position = u_projTrans * vec4(a_position, 1.0);
}
