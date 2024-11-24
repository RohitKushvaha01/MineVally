#ifndef CALLBACKS_H
#define CALLBACKS_H

#include <GLFW/glfw3.h>

void processInput(GLFWwindow* window, float deltaTime);
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
void framebuffer_size_callback(GLFWwindow* window, int width, int height);

#endif // CALLBACKS_H
