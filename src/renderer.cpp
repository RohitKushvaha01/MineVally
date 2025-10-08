#include "renderer.hpp"
#include <glm/gtc/type_ptr.hpp>
#include "shader.hpp"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include <iostream>
#include "ui/ui.hpp"
#include <algorithm>

namespace std {
    template <>
    struct hash<glm::ivec3> {
        size_t operator()(const glm::ivec3& v) const {
            size_t h1 = hash<int>()(v.x);
            size_t h2 = hash<int>()(v.y);
            size_t h3 = hash<int>()(v.z);
            return h1 ^ (h2 << 1) ^ (h3 << 2);
        }
    };
}

Renderer::Renderer() : shaderProgram(0), texture(0) {}

void Renderer::compactMeshes() {
    // Remove all deleted mesh entries to free memory
    auto it = std::remove_if(meshes.begin(), meshes.end(),
        [](const Mesh& m) { return m.indexCount == 0; });
    meshes.erase(it, meshes.end());

    // Force deallocation by shrinking capacity
    meshes.shrink_to_fit();
}

void Renderer::initialize(GLFWwindow* window) {

    glfwSwapInterval(0);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_MULTISAMPLE);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);           
    glFrontFace(GL_CW);           
    glDepthFunc(GL_LESS);

    // Clean up existing resources if re-initializing
    if (shaderProgram != 0) {
        glDeleteProgram(shaderProgram);
        shaderProgram = 0;
    }

    shaderProgram = createShader();
    loadTexture("texture.png");

    glClearColor(0.53f, 0.81f, 0.92f, 1.0f);

    modelLoc = glGetUniformLocation(shaderProgram, "model");
    viewLoc = glGetUniformLocation(shaderProgram, "view");
    projectionLoc = glGetUniformLocation(shaderProgram, "projection");

    initUi(window);
}

void Renderer::loadTexture(const char *path)
{
    // Delete existing texture if one exists
    if (texture != 0) {
        glDeleteTextures(1, &texture);
        texture = 0;
    }

    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    // Set texture parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    // Load and generate the texture
    int width, height, nrChannels;
    stbi_set_flip_vertically_on_load(true);
    unsigned char *data = stbi_load(path, &width, &height, &nrChannels, 4);

    if (data)
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    else
    {
        std::cerr << "Failed to load texture" << std::endl;
    }

    stbi_image_free(data);
}


size_t Renderer::addMesh(const std::vector<Vertex>& vertices, const std::vector<unsigned int>& indices) {
    Mesh mesh;
    glGenVertexArrays(1, &mesh.VAO);
    glGenBuffers(1, &mesh.VBO);
    glGenBuffers(1, &mesh.EBO);

    glBindVertexArray(mesh.VAO);

    glBindBuffer(GL_ARRAY_BUFFER, mesh.VBO);
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(Vertex), vertices.data(), GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(unsigned int), indices.data(), GL_STATIC_DRAW);

    mesh.indexCount = indices.size();

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, position));
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, texCoord));
    glEnableVertexAttribArray(1);

    glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, ao));
    glEnableVertexAttribArray(2);

    meshes.push_back(mesh);
    return meshes.size() - 1;
}

void Renderer::removeMesh(size_t index) {
    if (index >= meshes.size()) return;

    // Skip if already deleted
    if (meshes[index].indexCount == 0) return;

    // Delete OpenGL resources
    glDeleteVertexArrays(1, &meshes[index].VAO);
    glDeleteBuffers(1, &meshes[index].VBO);
    glDeleteBuffers(1, &meshes[index].EBO);

    // Mark as deleted by setting indexCount to 0
    meshes[index].indexCount = 0;
    meshes[index].VAO = 0;
    meshes[index].VBO = 0;
    meshes[index].EBO = 0;
}

void Renderer::render(const glm::mat4& view, const glm::mat4& projection) {
    glUseProgram(shaderProgram);

    glUniformMatrix4fv(modelLoc, 1, GL_FALSE, glm::value_ptr(glm::mat4(1.0f)));
    glUniformMatrix4fv(viewLoc, 1, GL_FALSE, glm::value_ptr(view));
    glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, glm::value_ptr(projection));

    glBindTexture(GL_TEXTURE_2D, texture);

    // Render each mesh individually, but skip deleted ones
    for (auto& mesh : meshes) {
        if (mesh.indexCount > 0) { // Skip deleted meshes
            glBindVertexArray(mesh.VAO);
            glDrawElements(GL_TRIANGLES, mesh.indexCount, GL_UNSIGNED_INT, 0);
        }
    }

    renderUi();
}

void Renderer::dispose() {
    // Clean up UI first
    disposeUi();

    // Clean up all meshes
    for (auto& mesh : meshes) {
        if (mesh.indexCount > 0) { // Only delete if not already deleted
            glDeleteVertexArrays(1, &mesh.VAO);
            glDeleteBuffers(1, &mesh.VBO);
            glDeleteBuffers(1, &mesh.EBO);
        }
    }
    meshes.clear();

    // Clean up shader program
    if (shaderProgram != 0) {
        glDeleteProgram(shaderProgram);
        shaderProgram = 0;
    }

    // Clean up texture
    if (texture != 0) {
        glDeleteTextures(1, &texture);
        texture = 0;
    }
}
