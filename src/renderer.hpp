#pragma once
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <vector>
#include "chunk.hpp"
#include <glm/glm.hpp>

struct Mesh
{
    GLuint VAO = 0;
    GLuint VBO = 0;
    GLuint EBO = 0;
    GLuint indexCount = 0;
};

class Renderer
{
private:
    unsigned int shaderProgram;
    unsigned int texture;
    void loadTexture(const char *path);

public:
    Renderer();

    void initialize(GLFWwindow *window);

    size_t addMesh(const std::vector<Vertex> &vertices, const std::vector<unsigned int> &indices);
    void removeMesh(size_t index);
    
    // Render all meshes
    void render(const glm::mat4 &view, const glm::mat4 &projection);
    void compactMeshes();

    void dispose();

    std::vector<Mesh> meshes;

    int modelLoc;
    int viewLoc;
    int projectionLoc;
};
