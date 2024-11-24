
#include <iostream>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>


#include "settings.hpp"
#include "shader.hpp"
#include "callbacks.h"


class Camera {
public:
    glm::vec3 position;
    glm::vec3 front;
    glm::vec3 up;
    glm::vec3 right;
    glm::vec3 worldUp;
    float yaw, pitch;
    float movementSpeed;
    float mouseSensitivity;
    float zoom;

    Camera(glm::vec3 position, glm::vec3 up, float yaw, float pitch)
        : front(glm::vec3(0.0f, 0.0f, -1.0f)), movementSpeed(2.5f), mouseSensitivity(0.1f), zoom(45.0f) {
        this->position = position;
        this->worldUp = up;
        this->yaw = yaw;
        this->pitch = pitch;
        this->updateCameraVectors();
    }

    glm::mat4 GetViewMatrix() {
        return glm::lookAt(position, position + front, up);
    }

    void ProcessKeyboard(int direction, float deltaTime) {
        float velocity = movementSpeed * deltaTime;
        if (direction == GLFW_KEY_W)
            position += front * velocity;
        if (direction == GLFW_KEY_S)
            position -= front * velocity;
        if (direction == GLFW_KEY_A)
            position -= right * velocity;
        if (direction == GLFW_KEY_D)
            position += right * velocity;
    }

    void ProcessMouseMovement(float xOffset, float yOffset, GLboolean constrainPitch = true) {
        xOffset *= mouseSensitivity;
        yOffset *= mouseSensitivity;

        yaw   += xOffset;
        pitch += yOffset;

        if (constrainPitch) {
            if (pitch > 89.0f) pitch = 89.0f;
            if (pitch < -89.0f) pitch = -89.0f;
        }

        updateCameraVectors();
    }

private:
    void updateCameraVectors() {
        glm::vec3 front;
        front.x = cos(glm::radians(yaw)) * cos(glm::radians(pitch));
        front.y = sin(glm::radians(pitch));
        front.z = sin(glm::radians(yaw)) * cos(glm::radians(pitch));
        this->front = glm::normalize(front);

        right = glm::normalize(glm::cross(front, worldUp));
        up = glm::normalize(glm::cross(right, front));
    }
};
