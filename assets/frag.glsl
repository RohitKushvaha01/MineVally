#version 330 core
precision mediump float;

uniform sampler2D u_texture;
varying vec3 v_normal;
varying vec2 v_texCoord;

void main() {
    vec4 texColor = texture2D(u_texture, v_texCoord);
    gl_FragColor = texColor;
}
