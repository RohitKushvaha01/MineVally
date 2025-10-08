#include "frustum.hpp"


void Frustum::update(const glm::mat4& vp) {
    // Extract 6 planes from view-projection matrix
    // Left
    planes[0].normal = glm::vec3(vp[0][3] + vp[0][0], vp[1][3] + vp[1][0], vp[2][3] + vp[2][0]);
    planes[0].distance = vp[3][3] + vp[3][0];
    
    // Right
    planes[1].normal = glm::vec3(vp[0][3] - vp[0][0], vp[1][3] - vp[1][0], vp[2][3] - vp[2][0]);
    planes[1].distance = vp[3][3] - vp[3][0];
    
    // Bottom
    planes[2].normal = glm::vec3(vp[0][3] + vp[0][1], vp[1][3] + vp[1][1], vp[2][3] + vp[2][1]);
    planes[2].distance = vp[3][3] + vp[3][1];
    
    // Top
    planes[3].normal = glm::vec3(vp[0][3] - vp[0][1], vp[1][3] - vp[1][1], vp[2][3] - vp[2][1]);
    planes[3].distance = vp[3][3] - vp[3][1];
    
    // Near
    planes[4].normal = glm::vec3(vp[0][3] + vp[0][2], vp[1][3] + vp[1][2], vp[2][3] + vp[2][2]);
    planes[4].distance = vp[3][3] + vp[3][2];
    
    // Far
    planes[5].normal = glm::vec3(vp[0][3] - vp[0][2], vp[1][3] - vp[1][2], vp[2][3] - vp[2][2]);
    planes[5].distance = vp[3][3] - vp[3][2];
    
    // Normalize
    for (auto& plane : planes) {
        float len = glm::length(plane.normal);
        plane.normal /= len;
        plane.distance /= len;
    }
}

bool Frustum::isBoxVisible(const AABB& box) const {
    for (const auto& plane : planes) {
        // Get positive vertex
        glm::vec3 pv = box.min;
        if (plane.normal.x >= 0) pv.x = box.max.x;
        if (plane.normal.y >= 0) pv.y = box.max.y;
        if (plane.normal.z >= 0) pv.z = box.max.z;
        
        if (plane.getSignedDistanceToPlane(pv) < 0)
            return false;
    }
    return true;
}