// frustum.hpp
#pragma once
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <array>

struct Plane {
    glm::vec3 normal;
    float distance;

    Plane() : normal(0.0f), distance(0.0f) {}

    float getSignedDistanceToPlane(const glm::vec3& point) const {
        return glm::dot(normal, point) + distance;
    }
};

struct AABB {
    glm::vec3 min;
    glm::vec3 max;

    AABB() : min(0.0f), max(0.0f) {}
    AABB(const glm::vec3& min, const glm::vec3& max) : min(min), max(max) {}

    glm::vec3 getCenter() const {
        return (min + max) * 0.5f;
    }

    glm::vec3 getExtents() const {
        return (max - min) * 0.5f;
    }
};

class Frustum {
public:
    enum Planes {
        LEFT = 0,
        RIGHT,
        BOTTOM,
        TOP,
        NEAR,
        FAR,
        COUNT
    };

private:
    std::array<Plane, COUNT> planes;

public:
    Frustum() {}

    // Extract frustum planes from view-projection matrix
    void update(const glm::mat4& viewProjection) {
        // Left plane
        planes[LEFT].normal.x = viewProjection[0][3] + viewProjection[0][0];
        planes[LEFT].normal.y = viewProjection[1][3] + viewProjection[1][0];
        planes[LEFT].normal.z = viewProjection[2][3] + viewProjection[2][0];
        planes[LEFT].distance = viewProjection[3][3] + viewProjection[3][0];

        // Right plane
        planes[RIGHT].normal.x = viewProjection[0][3] - viewProjection[0][0];
        planes[RIGHT].normal.y = viewProjection[1][3] - viewProjection[1][0];
        planes[RIGHT].normal.z = viewProjection[2][3] - viewProjection[2][0];
        planes[RIGHT].distance = viewProjection[3][3] - viewProjection[3][0];

        // Bottom plane
        planes[BOTTOM].normal.x = viewProjection[0][3] + viewProjection[0][1];
        planes[BOTTOM].normal.y = viewProjection[1][3] + viewProjection[1][1];
        planes[BOTTOM].normal.z = viewProjection[2][3] + viewProjection[2][1];
        planes[BOTTOM].distance = viewProjection[3][3] + viewProjection[3][1];

        // Top plane
        planes[TOP].normal.x = viewProjection[0][3] - viewProjection[0][1];
        planes[TOP].normal.y = viewProjection[1][3] - viewProjection[1][1];
        planes[TOP].normal.z = viewProjection[2][3] - viewProjection[2][1];
        planes[TOP].distance = viewProjection[3][3] - viewProjection[3][1];

        // Near plane
        planes[NEAR].normal.x = viewProjection[0][3] + viewProjection[0][2];
        planes[NEAR].normal.y = viewProjection[1][3] + viewProjection[1][2];
        planes[NEAR].normal.z = viewProjection[2][3] + viewProjection[2][2];
        planes[NEAR].distance = viewProjection[3][3] + viewProjection[3][2];

        // Far plane
        planes[FAR].normal.x = viewProjection[0][3] - viewProjection[0][2];
        planes[FAR].normal.y = viewProjection[1][3] - viewProjection[1][2];
        planes[FAR].normal.z = viewProjection[2][3] - viewProjection[2][2];
        planes[FAR].distance = viewProjection[3][3] - viewProjection[3][2];

        // Normalize planes
        for (int i = 0; i < COUNT; i++) {
            float length = glm::length(planes[i].normal);
            planes[i].normal /= length;
            planes[i].distance /= length;
        }
    }

    // Check if AABB is inside frustum
    bool isBoxVisible(const AABB& box) const {
        for (int i = 0; i < COUNT; i++) {
            // Get the positive vertex (farthest point in direction of plane normal)
            glm::vec3 positiveVertex = box.min;

            if (planes[i].normal.x >= 0) positiveVertex.x = box.max.x;
            if (planes[i].normal.y >= 0) positiveVertex.y = box.max.y;
            if (planes[i].normal.z >= 0) positiveVertex.z = box.max.z;

            // If positive vertex is outside, the box is completely outside
            if (planes[i].getSignedDistanceToPlane(positiveVertex) < 0) {
                return false;
            }
        }

        return true;
    }

    // Alternative: Check with center and radius (faster but less accurate)
    bool isSphereVisible(const glm::vec3& center, float radius) const {
        for (int i = 0; i < COUNT; i++) {
            if (planes[i].getSignedDistanceToPlane(center) < -radius) {
                return false;
            }
        }
        return true;
    }
};
