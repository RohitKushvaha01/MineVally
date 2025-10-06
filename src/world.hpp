#pragma once
#include "chunk.hpp"
#include "renderer.hpp"
#include <unordered_map>
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <mutex>
#include <atomic>
#include <thread>
#include <queue>
#include <unordered_set>

// Forward declarations
struct ChunkMeshData;
struct ivec3Hash;
struct ivec3Equal;

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
    
    // Thread synchronization
    static std::mutex chunksMutex;
    static std::mutex chunkQueueMutex;
    static std::queue<ChunkMeshData> pendingChunks;
    static std::unordered_set<glm::ivec3, ivec3Hash, ivec3Equal> removedChunks;
    static std::atomic<bool> isShuttingDown;
    static std::thread workerThread;
    static int renderDistance;
    static std::thread chunkManagerThread;
    static glm::ivec3 lastCameraChunk; 
    
    // Renderer instance
    static Renderer renderer;
    
    void generateChunkAsync(const glm::ivec3& pos);
    void processPendingChunks();
    void chunkManagerLoop();

    glm::ivec3 worldToChunkPos(const glm::vec3& worldPos);
    bool isChunkInRange(const glm::ivec3& chunkPos, const glm::ivec3& centerChunk);
    std::vector<glm::ivec3> getChunksInRange(const glm::ivec3& centerChunk);
  

public:
    World();
    
    // Prevent copying
    World(const World&) = delete;
    World& operator=(const World&) = delete;
    
    void addChunk(const glm::ivec3& position);
    void removeChunk(const glm::ivec3& position);
    
    void initialize(GLFWwindow *window);
    void render(const glm::mat4 &projection);
    void dispose();

    void updateChunks();  // NEW - optional manual update
    
    // Getters/Setters
    void setRenderDistance(int distance) { renderDistance = distance; }
    int getRenderDistance() const { return renderDistance; }
};