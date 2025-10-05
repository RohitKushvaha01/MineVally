#pragma once
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <vector>
#include "chunk.hpp"

class Renderer
{
private:
    unsigned int VAO, VBO, EBO;
    unsigned int shaderProgram;
    unsigned int texture;
    void loadTexture(const char *path);

public:
    Renderer();
    ~Renderer();

    void initialize(GLFWwindow *window);
    void setupBuffers(const std::vector<Vertex> &vertices, const std::vector<unsigned int> &indices);
    void render(const glm::mat4 &view, const glm::mat4 &projection);
    void dispose();
    
    int modelLoc;
    int viewLoc;
    int projectionLoc;
    glm::mat4 model;
};