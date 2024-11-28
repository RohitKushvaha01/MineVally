#pragma once
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <vector>
#include "chunk.hpp"

class Renderer {
private:
    unsigned int VAO, VBO, EBO;
    unsigned int shaderProgram;
    unsigned int texture;
    
public:
    Renderer();
    ~Renderer();
    
    void initialize();
    void setupBuffers(const std::vector<Vertex>& vertices, const std::vector<unsigned int>& indices);
    void loadTexture(const char* path);
    void render(const glm::mat4& view, const glm::mat4& projection);
};