#include "callbacks.h"
#include "settings.hpp"
#include <iostream>

// Camera instance
Camera camera = Camera(glm::vec3(0.0f, 0.0f, 3.0f), glm::vec3(0.0f, 1.0f, 0.0f), -90.0f, 0.0f);

// Cursor state
bool isCursorVisible = false;
// Key state for toggling
bool toggleKeyPressed = false;

// Process keyboard input for camera movement
void processInput(GLFWwindow *window, float deltaTime)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
    {
        glfwSetWindowShouldClose(window, true);
    }
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(GLFW_KEY_W, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(GLFW_KEY_S, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(GLFW_KEY_A, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(GLFW_KEY_D, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(GLFW_KEY_UP, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS)
    {
        camera.ProcessKeyboard(GLFW_KEY_DOWN, deltaTime);
    }
    if (glfwGetKey(window, GLFW_KEY_H) == GLFW_PRESS)
    {
        if (!toggleKeyPressed) // Ensure the toggle happens only once per key press
        {
            toggleKeyPressed = true; // Mark the key as pressed
            isCursorVisible = !isCursorVisible;

            if (isCursorVisible)
            {
                glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL); // Show cursor
            }
            else
            {
                glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED); // Hide and disable cursor
            }
        }
    }
    else if (glfwGetKey(window, GLFW_KEY_H) == GLFW_RELEASE)
    {
        toggleKeyPressed = false; // Reset the toggle key state when released
    }
}

// Mouse callback for camera rotation
void mouse_callback(GLFWwindow *window, double xpos, double ypos)
{
    if (isCursorVisible)
    {
        return;
    }

    static float lastX = SCR_WIDTH / 2.0f;
    static float lastY = SCR_HEIGHT / 2.0f;

    float xOffset = xpos - lastX;
    float yOffset = lastY - ypos; // reversed since y-coordinates go from bottom to top

    lastX = xpos;
    lastY = ypos;

    camera.ProcessMouseMovement(xOffset, yOffset);
}

void framebuffer_size_callback(GLFWwindow *window, int width, int height)
{
    glViewport(0, 0, width, height);
    SCR_WIDTH = width;
    SCR_HEIGHT = height;
}
