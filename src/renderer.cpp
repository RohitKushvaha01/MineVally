#include "renderer.hpp"
#include <glm/gtc/type_ptr.hpp>
#include "shader.hpp"

#define STB_IMAGE_IMPLEMENTATION
#include "deps/stb_image.h"
#include <iostream>
#include "ui/ui.hpp"


int modelLoc;
int viewLoc;
int projectionLoc;


Renderer::Renderer() : VAO(0), VBO(0), EBO(0), shaderProgram(0), texture(0){}

Renderer::~Renderer(){
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteBuffers(1, &EBO);
    glDeleteProgram(shaderProgram);
    glDeleteTextures(1, &texture);
}

std::vector<Vertex> vertices;
std::vector<unsigned int> indices;


void Renderer::initialize(GLFWwindow *window)
{

    setupBuffers(vertices, indices);
    loadTexture("texture.png");

    // Create and configure shader program
    shaderProgram = createShader();

            // Generate buffers and vertex array object
            glGenVertexArrays(1, &VAO);
            glGenBuffers(1, &VBO);
            glGenBuffers(1, &EBO);

    glClearColor(0.53f, 0.81f, 0.92f, 1.0f);
    modelLoc = glGetUniformLocation(shaderProgram, "model");
    viewLoc = glGetUniformLocation(shaderProgram, "view");
    projectionLoc = glGetUniformLocation(shaderProgram, "projection");

    initUi(window);
}


GLuint indexCount;
void Renderer::setupBuffers(const std::vector<Vertex> &vertices, const std::vector<unsigned int> &indices)
{
    glBindVertexArray(VAO);

    // Set up vertex buffer
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(Vertex), vertices.data(), GL_STATIC_DRAW);

    // Set up element buffer
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(unsigned int), indices.data(), GL_STATIC_DRAW);
    indexCount = indices.size();    
    // position
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, position));
    glEnableVertexAttribArray(0);

    //textCoord
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, texCoord));
    glEnableVertexAttribArray(1);

    //ao
    glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, ao));
    glEnableVertexAttribArray(2);
}

void Renderer::loadTexture(const char *path)
{
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

void Renderer::render(const glm::mat4 &view, const glm::mat4 &projection)
{
    
    glUseProgram(shaderProgram);

    glUniformMatrix4fv(modelLoc, 1, GL_FALSE, glm::value_ptr(glm::mat4(1.0f)));  // dynamic model matrix
    glUniformMatrix4fv(viewLoc, 1, GL_FALSE, glm::value_ptr(view));
    glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, glm::value_ptr(projection));

    // Bind texture
    glBindTexture(GL_TEXTURE_2D, texture);

    // Render the mesh
    glBindVertexArray(VAO);

    // Draw with the correct index count
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_INT, 0);

    renderUi();
}

void Renderer::dispose(){
    disposeUi();
}
