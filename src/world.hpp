#pragma once
#include "chunk.hpp"
#include <unordered_map>
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>




// Hash function for glm::ivec3 to use in unordered_map
struct Vec3Hash {
    size_t operator()(const glm::ivec3& v) const {
        return std::hash<int>()(v.x) ^ 
               (std::hash<int>()(v.y) << 1) ^ 
               (std::hash<int>()(v.z) << 2);
    }
};

class World {
private:
    std::unordered_map<glm::ivec3, Chunk, Vec3Hash> chunks;
    std::vector<Vertex> combinedVertices;
    std::vector<unsigned int> combinedIndices;
    bool meshNeedsUpdate;

public:
    World();
    void addChunk(const glm::ivec3& position);
    void removeChunk(const glm::ivec3& position);
    void generateCombinedMesh(const glm::mat4 &viewProjection);
    bool isChunkInView(const glm::ivec3 &chunkPos, const glm::mat4 &viewProjection);

    void initialize(GLFWwindow *window);
    void render(const glm::mat4 &projection);
    void dispose();
    

    const std::vector<Vertex> &getVertices() const { return combinedVertices; }
    const std::vector<unsigned int>& getIndices() const { return combinedIndices; }
    bool needsUpdate() const { return meshNeedsUpdate; }
    void setNeedsUpdate() { meshNeedsUpdate = true; }
};