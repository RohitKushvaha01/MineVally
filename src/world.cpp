#include "world.hpp"
#include <thread>
#include <mutex>
#include <atomic>
#include "renderer.hpp"
#include "camera.hpp"
#include <queue>
#include <optional>
#include <unordered_set>
#include <cmath>
#include <algorithm>

// Custom hash and equality for glm::ivec3
struct ivec3Hash {
    size_t operator()(const glm::ivec3& v) const {
        size_t h1 = std::hash<int>()(v.x);
        size_t h2 = std::hash<int>()(v.y);
        size_t h3 = std::hash<int>()(v.z);
        return h1 ^ (h2 << 1) ^ (h3 << 2);
    }
};

struct ivec3Equal {
    bool operator()(const glm::ivec3& a, const glm::ivec3& b) const {
        return a.x == b.x && a.y == b.y && a.z == b.z;
    }
};

struct ChunkMeshData {
    glm::ivec3 position;
    std::vector<Vertex> vertices;
    std::vector<unsigned int> indices;
};

// Member variables
std::mutex World::chunksMutex;
std::mutex World::chunkQueueMutex;
std::queue<ChunkMeshData> World::pendingChunks;
std::unordered_set<glm::ivec3, ivec3Hash, ivec3Equal> World::removedChunks;
std::atomic<bool> World::isShuttingDown(false);
std::thread World::workerThread;
std::thread World::chunkManagerThread;
Renderer World::renderer;
int World::renderDistance = 8;
glm::ivec3 World::lastCameraChunk = glm::ivec3(INT_MAX, INT_MAX, INT_MAX);


// Convert world position to chunk position
glm::ivec3 World::worldToChunkPos(const glm::vec3& worldPos) {
    return glm::ivec3(
        std::floor(worldPos.x / CHUNK_SIZE),
        std::floor(worldPos.y / CHUNK_SIZE),
        std::floor(worldPos.z / CHUNK_SIZE)
    );
}

// Check if chunk is within render distance
bool World::isChunkInRange(const glm::ivec3& chunkPos, const glm::ivec3& centerChunk) {
    int dx = chunkPos.x - centerChunk.x;
    int dy = chunkPos.y - centerChunk.y;
    int dz = chunkPos.z - centerChunk.z;
    
    // Use cylindrical distance (ignore Y for more natural loading)
    int horizontalDistSq = dx * dx + dz * dz;
    int verticalDist = std::abs(dy);
    
    return horizontalDistSq <= renderDistance * renderDistance && 
           verticalDist <= renderDistance / 2;
}

// Get all chunks that should be loaded around a position
std::vector<glm::ivec3> World::getChunksInRange(const glm::ivec3& centerChunk) {
    std::vector<glm::ivec3> result;
    
    int verticalRange = renderDistance / 2;
    
    for (int y = -verticalRange; y <= verticalRange; y++) {
        for (int x = -renderDistance; x <= renderDistance; x++) {
            for (int z = -renderDistance; z <= renderDistance; z++) {
                glm::ivec3 chunkPos = centerChunk + glm::ivec3(x, y, z);
                if (isChunkInRange(chunkPos, centerChunk)) {
                    result.push_back(chunkPos);
                }
            }
        }
    }
    
    // Sort by distance from center (closer chunks load first)
    std::sort(result.begin(), result.end(), 
        [centerChunk](const glm::ivec3& a, const glm::ivec3& b) {
            int distA = (a.x - centerChunk.x) * (a.x - centerChunk.x) + 
                       (a.z - centerChunk.z) * (a.z - centerChunk.z) +
                       (a.y - centerChunk.y) * (a.y - centerChunk.y);
            int distB = (b.x - centerChunk.x) * (b.x - centerChunk.x) + 
                       (b.z - centerChunk.z) * (b.z - centerChunk.z) +
                       (b.y - centerChunk.y) * (b.y - centerChunk.y);
            return distA < distB;
        });
    
    return result;
}

World::World(){}

// Background thread that manages chunk loading/unloading
void World::chunkManagerLoop() {
    printf("Chunk manager thread started\n");
    
    while (!isShuttingDown.load()) {
        glm::vec3 cameraPos = camera.position;
        glm::ivec3 currentCameraChunk = worldToChunkPos(cameraPos);
        
        // Only update chunks if camera moved to a new chunk
        if (currentCameraChunk != lastCameraChunk) {
            printf("Camera moved to chunk (%d, %d, %d)\n", 
                   currentCameraChunk.x, currentCameraChunk.y, currentCameraChunk.z);
            
            lastCameraChunk = currentCameraChunk;
            
            // Get chunks that should be loaded
            std::vector<glm::ivec3> desiredChunks = getChunksInRange(currentCameraChunk);
            std::unordered_set<glm::ivec3, ivec3Hash, ivec3Equal> desiredSet(
                desiredChunks.begin(), desiredChunks.end());
            
            // Remove chunks that are too far
            std::vector<glm::ivec3> chunksToRemove;
            {
                std::lock_guard<std::mutex> lock(chunksMutex);
                for (const auto& [pos, chunk] : chunks) {
                    if (desiredSet.count(pos) == 0) {
                        chunksToRemove.push_back(pos);
                    }
                }
            }
            
            for (const auto& pos : chunksToRemove) {
                removeChunk(pos);
            }
            
            // Add new chunks that are in range
            for (const auto& pos : desiredChunks) {
                if (isShuttingDown.load()) break;
                
                bool needsCreation = false;
                {
                    std::lock_guard<std::mutex> lock(chunksMutex);
                    needsCreation = chunks.find(pos) == chunks.end();
                }
                
                if (needsCreation) {
                    addChunk(pos);
                    // Small delay to prevent overwhelming the system
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                }
            }
        }
        
        // Check every 100ms for camera movement
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    printf("Chunk manager thread stopped\n");
}

void World::generateChunkAsync(const glm::ivec3& pos) {
    std::thread([this, pos]() {
        if (isShuttingDown.load()) return;

        {
            std::lock_guard<std::mutex> lock(chunkQueueMutex);
            if (removedChunks.count(pos) > 0) return;
        }

        std::vector<Vertex> vertices;
        std::vector<unsigned int> indices;

        {
            std::lock_guard<std::mutex> lock(chunksMutex);
            if (isShuttingDown.load()) return;
            
            auto it = chunks.find(pos);
            if (it == chunks.end()) return;
            it->second.generateMesh(vertices, indices);
        }

        glm::vec3 offset(pos.x * CHUNK_SIZE, pos.y * CHUNK_SIZE, pos.z * CHUNK_SIZE);
        for (auto& v : vertices) v.position += offset;

        {
            std::lock_guard<std::mutex> lock(chunkQueueMutex);
            if (removedChunks.count(pos) == 0 && !isShuttingDown.load()) {
                pendingChunks.push({ pos, std::move(vertices), std::move(indices) });
            }
        }
    }).detach();
}

void World::processPendingChunks() {
    std::unique_lock<std::mutex> lock(chunkQueueMutex, std::try_to_lock);
    if (!lock.owns_lock()) return;

    // Process multiple chunks per frame for faster loading
    int maxChunksPerFrame = 5;
    int processed = 0;
    
    while (!pendingChunks.empty() && processed < maxChunksPerFrame) {
        const auto& meshData = pendingChunks.front();

        {
            std::lock_guard<std::mutex> chunkLock(chunksMutex);
            auto it = chunks.find(meshData.position);
            if (it != chunks.end() && removedChunks.count(meshData.position) == 0) {
                size_t meshIndex = renderer.addMesh(meshData.vertices, meshData.indices);
                it->second.meshIndex = meshIndex;
            }
        }

        pendingChunks.pop();
        processed++;
    }
}

void World::render(const glm::mat4 &projection) {
    if (isShuttingDown.load()) return;
    
    processPendingChunks();
    glm::mat4 view = camera.GetViewMatrix();
    renderer.render(view, projection);
}

void World::initialize(GLFWwindow *window) {
    isShuttingDown.store(false);
    renderer.initialize(window);
    
    // Initialize camera chunk position
    lastCameraChunk = worldToChunkPos(camera.position);
    
    // Start the chunk manager thread
    chunkManagerThread = std::thread([this]() {
        chunkManagerLoop();
    });
    
    printf("World initialized with dynamic chunk loading\n");
}

void World::dispose() {
    printf("Starting world disposal\n");
    
    // Signal shutdown
    isShuttingDown.store(true);
    
    // Wait for chunk manager thread
    if (chunkManagerThread.joinable()) {
        chunkManagerThread.join();
        printf("Chunk manager thread joined\n");
    }
    
    // Wait for worker thread
    if (workerThread.joinable()) {
        workerThread.join();
        printf("Worker thread joined\n");
    }
    
    // Give detached threads time to finish
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // Clean up pending chunks
    {
        std::lock_guard<std::mutex> lock(chunkQueueMutex);
        while (!pendingChunks.empty()) {
            pendingChunks.pop();
        }
        removedChunks.clear();
    }
    
    // Clean up all chunks
    {
        std::lock_guard<std::mutex> lock(chunksMutex);
        for (auto& [pos, chunk] : chunks) {
            if (chunk.hasMesh()) {
                renderer.removeMesh(chunk.meshIndex);
            }
        }
        chunks.clear();
    }
    
    renderer.compactMeshes();
    renderer.dispose();
    
    printf("World disposal complete\n");
}

void World::addChunk(const glm::ivec3& pos) {
    if (isShuttingDown.load()) return;
    
    Chunk chunk;
    chunk.initialize(pos.x, pos.y, pos.z);
    
    {
        std::lock_guard<std::mutex> lock(chunksMutex);
        chunks[pos] = chunk;
    }
    
    {
        std::lock_guard<std::mutex> lock(chunkQueueMutex);
        removedChunks.erase(pos);
    }
    
    generateChunkAsync(pos);
}

void World::removeChunk(const glm::ivec3 &position) {
    {
        std::lock_guard<std::mutex> lock(chunkQueueMutex);
        removedChunks.insert(position);
        
        std::queue<ChunkMeshData> filteredQueue;
        while (!pendingChunks.empty()) {
            if (pendingChunks.front().position != position) {
                filteredQueue.push(std::move(pendingChunks.front()));
            }
            pendingChunks.pop();
        }
        pendingChunks = std::move(filteredQueue);
    }
    
    {
        std::lock_guard<std::mutex> lock(chunksMutex);
        auto it = chunks.find(position);
        if (it != chunks.end()) {
            if (it->second.hasMesh()) {
                renderer.removeMesh(it->second.meshIndex);
            }
            chunks.erase(it);
        }
    }
}

// Optional: Manual update call if you want to force chunk updates
void World::updateChunks() {
    glm::vec3 cameraPos = camera.position;
    glm::ivec3 currentCameraChunk = worldToChunkPos(cameraPos);
    
    if (currentCameraChunk != lastCameraChunk) {
        lastCameraChunk = currentCameraChunk;
    }
}