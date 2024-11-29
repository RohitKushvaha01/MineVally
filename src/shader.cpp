#include "shader.hpp"
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include "settings.hpp"

// vertex shader
const char *vertexShaderSource = R"glsl(


#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
in float a_ao;  // Per-vertex AO value

out vec2 TexCoord;
out float v_ao;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    TexCoord = aTexCoord;
    v_ao = a_ao / 3.0;
}






)glsl";

// fragment shader
const char *fragmentShaderSource = R"glsl(


#version 330 core
out vec4 FragColor;
in vec2 TexCoord;
in float v_ao;  // Interpolated AO value

uniform sampler2D texture1;

void main() {
    vec4 texColor = texture(texture1, TexCoord);
    float ambientStrength = 0.5;
    float aoFactor = ambientStrength + (1.0 - ambientStrength) * v_ao;
    // Apply AO while preserving original color
    FragColor = vec4(texColor.rgb * aoFactor, texColor.a);

    
}



)glsl";

// Function to create a shader program
unsigned int createShaderProgram()
{
    int success;
    char infoLog[512];

    // Vertex Shader
    unsigned int vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        std::cerr << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n"
                  << infoLog << std::endl;
    }

    // Fragment Shader
    unsigned int fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        std::cerr << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n"
                  << infoLog << std::endl;
    }

    // Shader Program
    unsigned int shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success)
    {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        std::cerr << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n"
                  << infoLog << std::endl;
    }

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return shaderProgram;
}

unsigned int createShader()
{
    return createShaderProgram();
}
