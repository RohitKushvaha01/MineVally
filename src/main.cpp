#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include "chunk.hpp"
#include "renderer.hpp"
#include "settings.hpp"
#include "callbacks.h"
#include "ui/ui.hpp"

int main() {
    // Initialize GLFW
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_SAMPLES, 4);

    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "MineVally", NULL, NULL);
    if (window == NULL) {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        std::cerr << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    // Set up window callbacks and settings
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    glViewport(0, 0, SCR_WIDTH, SCR_HEIGHT);

    // Initialize components
    Chunk chunk;
    Renderer renderer;
    
    chunk.initialize();
    renderer.initialize();

    std::vector<Vertex> vertices;
    std::vector<unsigned int> indices;
    chunk.generateMesh(vertices, indices);
    renderer.setupBuffers(vertices, indices);
    renderer.loadTexture("/home/rohit/minevally/texture.png");

    // Enable OpenGL features
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_MULTISAMPLE);
    
    float lastFrame = 0.0f;
    initUi(window);

    //disable vsync
    glfwSwapInterval(0);

    // Main render loop
    while (!glfwWindowShouldClose(window)) {
        float currentFrame = glfwGetTime();
        float deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        processInput(window, deltaTime);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glm::mat4 view = camera.GetViewMatrix();
        glm::mat4 projection = glm::perspective(glm::radians(45.0f), 
                                              (float)SCR_WIDTH / SCR_HEIGHT, 
                                              0.1f, 100.0f);

        renderer.render(view, projection);
        renderUi();
        
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    disposeUi();
    glfwTerminate();
    return 0;
}