#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <vector>
#include "settings.hpp"
#include "shader.hpp"
#include "callbacks.h"

#define STB_IMAGE_IMPLEMENTATION
#include "deps/stb_image.h"
#include "ui/ui.hpp"

const int CHUNK_SIZE = 16;

// Define a simple chunk: 1 for solid blocks, 0 for empty space
int chunk[CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE];

struct Vertex {
    glm::vec3 position;
    glm::vec2 texCoord;
};

int to1DIndex(int x, int y, int z)
{
    return x + (y * CHUNK_SIZE) + (z * CHUNK_SIZE * CHUNK_SIZE);
}

int getBlock(int x, int y, int z)
{
    return chunk[to1DIndex(x, y, z)];
}

void setBlock(int x, int y, int z, int value)
{
    chunk[to1DIndex(x, y, z)] = value;
}

bool isFaceVisible(int x, int y, int z, int face) {
    switch (face) {
        case 0: return y >= CHUNK_SIZE - 1 || getBlock(x, y + 1, z) == 0; // top
        case 1: return y <= 0 || getBlock(x, y - 1, z) == 0; // bottom
        case 2: return z >= CHUNK_SIZE - 1 || getBlock(x, y, z + 1) == 0; // front
        case 3: return z <= 0 || getBlock(x, y, z - 1) == 0; // back
        case 4: return x <= 0 || getBlock(x - 1, y, z) == 0; // left
        case 5: return x >= CHUNK_SIZE - 1 || getBlock(x + 1, y, z) == 0; // right
        default: return false;
    }
}

void generateChunkMesh(std::vector<Vertex>& vertices, std::vector<unsigned int>& indices) {
    vertices.clear();
    indices.clear();
    
    // Face vertices relative to block position
    const float faceVertices[6][12] = {
        // Top face
        {-0.5f, 0.5f, -0.5f,  0.5f, 0.5f, -0.5f,  0.5f, 0.5f, 0.5f,  -0.5f, 0.5f, 0.5f},
        // Bottom face
        {-0.5f, -0.5f, -0.5f,  0.5f, -0.5f, -0.5f,  0.5f, -0.5f, 0.5f,  -0.5f, -0.5f, 0.5f},
        // Front face
        {-0.5f, -0.5f, 0.5f,  0.5f, -0.5f, 0.5f,  0.5f, 0.5f, 0.5f,  -0.5f, 0.5f, 0.5f},
        // Back face
        {-0.5f, -0.5f, -0.5f,  0.5f, -0.5f, -0.5f,  0.5f, 0.5f, -0.5f,  -0.5f, 0.5f, -0.5f},
        // Left face
        {-0.5f, -0.5f, -0.5f,  -0.5f, -0.5f, 0.5f,  -0.5f, 0.5f, 0.5f,  -0.5f, 0.5f, -0.5f},
        // Right face
        {0.5f, -0.5f, -0.5f,  0.5f, -0.5f, 0.5f,  0.5f, 0.5f, 0.5f,  0.5f, 0.5f, -0.5f}
    };

    const float texCoords[8] = {
        0.0f, 0.0f,  // Bottom-left
        1.0f, 0.0f,  // Bottom-right
        1.0f, 1.0f,  // Top-right
        0.0f, 1.0f   // Top-left
    };

    // Iterate through all blocks in the chunk
    for (int x = 0; x < CHUNK_SIZE; ++x) {
        for (int y = 0; y < CHUNK_SIZE; ++y) {
            for (int z = 0; z < CHUNK_SIZE; ++z) {
                if (getBlock(x, y, z) == 1) {
                    // Check each face of the block
                    for (int face = 0; face < 6; ++face) {
                        if (isFaceVisible(x, y, z, face)) {
                            // Add the face to the mesh if it's visible
                            unsigned int indexOffset = vertices.size();
                            
                            // Add vertices for the face
                            for (int v = 0; v < 4; ++v) {
                                Vertex vertex;
                                vertex.position = glm::vec3(
                                    x + faceVertices[face][v * 3],
                                    y + faceVertices[face][v * 3 + 1],
                                    z + faceVertices[face][v * 3 + 2]
                                );
                                vertex.texCoord = glm::vec2(
                                    texCoords[v * 2],
                                    texCoords[v * 2 + 1]
                                );
                                vertices.push_back(vertex);
                            }

                            // Add indices for the face (two triangles)
                            indices.push_back(indexOffset);
                            indices.push_back(indexOffset + 1);
                            indices.push_back(indexOffset + 2);
                            indices.push_back(indexOffset + 2);
                            indices.push_back(indexOffset + 3);
                            indices.push_back(indexOffset);
                        }
                    }
                }
            }
        }
    }
}

void initializeChunk()
{
    for (int x = 0; x < CHUNK_SIZE; ++x)
    {
        for (int y = 0; y < CHUNK_SIZE; ++y)
        {
            for (int z = 0; z < CHUNK_SIZE; ++z)
            {
                setBlock(x, y, z, (y == 0) ? 1 : 0);
            }
        }
    }
}

int main()
{
    // Initialize GLFW
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_SAMPLES, 4);

    GLFWwindow *window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "MineVally", NULL, NULL);
    if (window == NULL)
    {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);

    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cerr << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glViewport(0, 0, SCR_WIDTH, SCR_HEIGHT);

    unsigned int shaderProgram = createShader();

    // Initialize chunk and generate mesh
    initializeChunk();
    std::vector<Vertex> vertices;
    std::vector<unsigned int> indices;
    generateChunkMesh(vertices, indices);

    // Configure VAO and buffers
    unsigned int VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);

    // Set up vertex buffer
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(Vertex), vertices.data(), GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(unsigned int), indices.data(), GL_STATIC_DRAW);

    // Set up vertex attributes
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, position));
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, texCoord));
    glEnableVertexAttribArray(1);

    // Texture setup
    unsigned int texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    int width, height, nrChannels;
    stbi_set_flip_vertically_on_load(true);
    unsigned char *data = stbi_load("/home/rohit/minevally/texture.png", &width, &height, &nrChannels, 4);
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

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_MULTISAMPLE);

    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

    float lastFrame = 0.0f;
    glm::mat4 model = glm::mat4(1.0f);
    
    int modelLoc = glGetUniformLocation(shaderProgram, "model");
    int viewLoc = glGetUniformLocation(shaderProgram, "view");
    int projectionLoc = glGetUniformLocation(shaderProgram, "projection");

    glUseProgram(shaderProgram);
    glUniformMatrix4fv(modelLoc, 1, GL_FALSE, glm::value_ptr(model));

    glBindTexture(GL_TEXTURE_2D, texture);

    glClearColor(0.53f, 0.81f, 0.92f, 1.0f);

    initUi(window);
    glfwSwapInterval(0);

    while (!glfwWindowShouldClose(window))
    {
        float currentFrame = glfwGetTime();
        float deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        processInput(window, deltaTime);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glm::mat4 view = camera.GetViewMatrix();
        glUniformMatrix4fv(viewLoc, 1, GL_FALSE, glm::value_ptr(view));

        glm::mat4 projection = glm::perspective(glm::radians(45.0f), (float)SCR_WIDTH / SCR_HEIGHT, 0.1f, 100.0f);
        glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, glm::value_ptr(projection));

        // Render the entire chunk mesh with a single draw call
        glBindVertexArray(VAO);
        glDrawElements(GL_TRIANGLES, indices.size(), GL_UNSIGNED_INT, 0);

        renderUi();
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    disposeUi();
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteBuffers(1, &EBO);

    glfwTerminate();
    return 0;
}