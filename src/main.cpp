#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include "settings.hpp"
#include "shader.hpp"
#include "callbacks.h"

#define STB_IMAGE_IMPLEMENTATION
#include "deps/stb_image.h"
#include "ui/ui.hpp"


const int CHUNK_SIZE = 16;

// Define a simple chunk: 1 for solid blocks, 0 for empty space
int chunk[CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE];

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


// Initialize the chunk with some data (e.g., solid base layer)
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
    glfwWindowHint(GLFW_SAMPLES, 4); // Request 4x MSAA

    // Create a GLFW window
    GLFWwindow *window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "MineVally", NULL, NULL);
    if (window == NULL)
    {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);

    // Initialize GLAD
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cerr << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glViewport(0, 0, SCR_WIDTH, SCR_HEIGHT);

    // Build and compile shader program
    unsigned int shaderProgram = createShader();

    // Cube vertices and indices

    float vertices[] = {
        // positions          // texture coords
        // Front face
        -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, // Bottom-left
        0.5f, -0.5f, 0.5f, 1.0f, 0.0f,  // Bottom-right
        0.5f, 0.5f, 0.5f, 1.0f, 1.0f,   // Top-right
        -0.5f, 0.5f, 0.5f, 0.0f, 1.0f,  // Top-left

        // Back face
        -0.5f, -0.5f, -0.5f, 0.0f, 0.0f, // Bottom-left
        0.5f, -0.5f, -0.5f, 1.0f, 0.0f,  // Bottom-right
        0.5f, 0.5f, -0.5f, 1.0f, 1.0f,   // Top-right
        -0.5f, 0.5f, -0.5f, 0.0f, 1.0f,  // Top-left

        // Left face
        -0.5f, -0.5f, -0.5f, 0.0f, 0.0f, // Bottom-left
        -0.5f, -0.5f, 0.5f, 1.0f, 0.0f,  // Bottom-right
        -0.5f, 0.5f, 0.5f, 1.0f, 1.0f,   // Top-right
        -0.5f, 0.5f, -0.5f, 0.0f, 1.0f,  // Top-left

        // Right face
        0.5f, -0.5f, -0.5f, 0.0f, 0.0f, // Bottom-left
        0.5f, -0.5f, 0.5f, 1.0f, 0.0f,  // Bottom-right
        0.5f, 0.5f, 0.5f, 1.0f, 1.0f,   // Top-right
        0.5f, 0.5f, -0.5f, 0.0f, 1.0f,  // Top-left

        // Top face
        -0.5f, 0.5f, 0.5f, 0.0f, 0.0f,  // Bottom-left
        0.5f, 0.5f, 0.5f, 1.0f, 0.0f,   // Bottom-right
        0.5f, 0.5f, -0.5f, 1.0f, 1.0f,  // Top-right
        -0.5f, 0.5f, -0.5f, 0.0f, 1.0f, // Top-left

        // Bottom face
        -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, // Bottom-left
        0.5f, -0.5f, 0.5f, 1.0f, 0.0f,  // Bottom-right
        0.5f, -0.5f, -0.5f, 1.0f, 1.0f, // Top-right
        -0.5f, -0.5f, -0.5f, 0.0f, 1.0f // Top-left
    };

    unsigned int indices[] = {
        // Front face
        0, 1, 2, 2, 3, 0,
        // Back face
        4, 5, 6, 6, 7, 4,
        // Left face
        8, 9, 10, 10, 11, 8,
        // Right face
        12, 13, 14, 14, 15, 12,
        // Top face
        16, 17, 18, 18, 19, 16,
        // Bottom face
        20, 21, 22, 22, 23, 20};

    // Configure VAO, VBO, and EBO
    unsigned int VAO, VBO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // Configure vertex attributes
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)0);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    unsigned int texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    // Set texture wrapping/filtering options
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); // Optional: wrapping
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); // Optional: wrapping

    // Use nearest-neighbor filtering for crisp textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    // Load image
    int width, height, nrChannels;
    stbi_set_flip_vertically_on_load(true); // Flip image vertically
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

    glBindVertexArray(0);

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_MULTISAMPLE);

    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED); // Hide the cursor

    float lastFrame = 0.0f;
    glm::mat4 model = glm::mat4(1.0f);
    // Before the render loop: Cache uniform locations and set static uniforms
    int modelLoc = glGetUniformLocation(shaderProgram, "model");
    int viewLoc = glGetUniformLocation(shaderProgram, "view");
    int projectionLoc = glGetUniformLocation(shaderProgram, "projection");

    // Static uniform: Set model matrix once since it doesn't change
    glUseProgram(shaderProgram);
    glUniformMatrix4fv(modelLoc, 1, GL_FALSE, glm::value_ptr(model));

    // Set texture once if it doesn't change
    glBindTexture(GL_TEXTURE_2D, texture);

    glClearColor(0.53f, 0.81f, 0.92f, 1.0f);

    // init ui
    initUi(window);

    // disable v-sync
    glfwSwapInterval(0);

    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        std::cerr << "OpenGL error: " << err << std::endl;
    }

    initializeChunk();

    while (!glfwWindowShouldClose(window))
    {
        // Frame time calculation
        float currentFrame = glfwGetTime();
        float deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        // Process input
        processInput(window, deltaTime);

        // Clear buffers

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Update view and projection matrices
        glm::mat4 view = camera.GetViewMatrix();
        glUniformMatrix4fv(viewLoc, 1, GL_FALSE, glm::value_ptr(view));

        glm::mat4 projection = glm::perspective(glm::radians(45.0f), (float)SCR_WIDTH / SCR_HEIGHT, 0.1f, 100.0f);
        glUniformMatrix4fv(projectionLoc, 1, GL_FALSE, glm::value_ptr(projection));

        // Render the chunk
        glBindVertexArray(VAO);

        for (int x = 0; x < CHUNK_SIZE; ++x)
        {
            for (int y = 0; y < CHUNK_SIZE; ++y)
            {
                for (int z = 0; z < CHUNK_SIZE; ++z)
                {
                    if (getBlock(x,y,z) == 1) // Only render solid blocks
                    {
                        // Translate each block based on its position in the chunk
                        glm::mat4 model = glm::mat4(1.0f);
                        model = glm::translate(model, glm::vec3(x, y, z));
                        glUniformMatrix4fv(modelLoc, 1, GL_FALSE, glm::value_ptr(model));

                        // Draw the cube
                        glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, 0);
                    }
                }
            }
        }

        // render ui
        renderUi();

        // Swap buffers and poll events
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // dispose ui
    disposeUi();
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteBuffers(1, &EBO);

    glfwTerminate();
    return 0;
}
