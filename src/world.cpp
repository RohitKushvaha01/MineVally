#include "world.hpp"
#include <thread>
#include <mutex>
#include "renderer.hpp"
#include "camera.hpp"

World::World() : meshNeedsUpdate(true) {}


Renderer renderer;

void World::initialize(GLFWwindow *window)
{
    
    for (int i = 0; i < 1; i++)
    {
        for (int j = 0; j < 1; j++)
        {
            addChunk(glm::vec3(i,0,j));
        }
    }
    renderer.initialize(window);
}

void World::render(const glm::mat4 &projection)
{
    if (needsUpdate())
        {
            generateCombinedMesh(camera.GetViewMatrix());
            renderer.setupBuffers(getVertices(), getIndices());
        }

    glm::mat4 view = camera.GetViewMatrix();
    renderer.render(view,projection);
}

void World::dispose()
{
    renderer.dispose();
}




void World::addChunk(const glm::ivec3& position) {
    Chunk chunk;
    chunk.initialize(position.x,position.z);
    chunks[position] = chunk;
    meshNeedsUpdate = true;
}

void World::removeChunk(const glm::ivec3& position) {
    chunks.erase(position);
    meshNeedsUpdate = true;
}

void World::generateCombinedMesh( const glm::mat4& viewProjection) {
    if (!meshNeedsUpdate) return;

    combinedVertices.clear();
    combinedIndices.clear();

    // Pre-allocate space to avoid reallocations
    size_t totalChunks = chunks.size();
    combinedVertices.reserve(totalChunks * CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * 24);
    combinedIndices.reserve(totalChunks * CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * 36);

    // For each chunk
    for (auto& [position, chunk] : chunks) {
        std::vector<Vertex> chunkVertices;
        std::vector<unsigned int> chunkIndices;
        
        // Generate mesh for this chunk
        chunk.generateMesh(chunkVertices, chunkIndices);

        // Calculate offset for the vertices based on chunk position
        glm::vec3 offset(
            position.x * CHUNK_SIZE,
            position.y * CHUNK_SIZE,
            position.z * CHUNK_SIZE
        );

        // Add vertices with offset
        size_t baseIndex = combinedVertices.size();
        for (const auto& vertex : chunkVertices) {
            Vertex offsetVertex = vertex;
            offsetVertex.position += offset;
            combinedVertices.push_back(offsetVertex);
        }

        // Add indices with offset
        for (unsigned int index : chunkIndices) {
            combinedIndices.push_back(index + baseIndex);
        }
    }

    meshNeedsUpdate = false;
}


bool World::isChunkInView(const glm::ivec3& chunkPos, const glm::mat4& viewProjection) {
    // Create AABB for the chunk
    glm::vec3 minPoint = glm::vec3(chunkPos * CHUNK_SIZE);
    glm::vec3 maxPoint = minPoint + glm::vec3(CHUNK_SIZE);

    // Define the 6 planes of the frustum (Left, Right, Bottom, Top, Near, Far)
    glm::mat4 inverseViewProjection = glm::inverse(viewProjection);
    glm::vec4 planes[6];

    planes[0] = inverseViewProjection * glm::vec4(1.0f, 0.0f, 0.0f, 0.0f); // Left
    planes[1] = inverseViewProjection * glm::vec4(-1.0f, 0.0f, 0.0f, 0.0f); // Right
    planes[2] = inverseViewProjection * glm::vec4(0.0f, 1.0f, 0.0f, 0.0f); // Bottom
    planes[3] = inverseViewProjection * glm::vec4(0.0f, -1.0f, 0.0f, 0.0f); // Top
    planes[4] = inverseViewProjection * glm::vec4(0.0f, 0.0f, 1.0f, 0.0f); // Near
    planes[5] = inverseViewProjection * glm::vec4(0.0f, 0.0f, -1.0f, 0.0f); // Far

    // Normalize the planes
    for (int i = 0; i < 6; ++i) {
        planes[i] = glm::normalize(planes[i]);
    }

    // Check if the chunk AABB intersects with the frustum
    for (int i = 0; i < 6; ++i) {
        glm::vec3 planeNormal = glm::vec3(planes[i]);
        float distance = glm::dot(planeNormal, glm::vec3(minPoint)) + planes[i].w;

        if (distance > 0.0f) {
            // The chunk is outside of the frustum if any plane faces away from the chunk
            return false;
        }
    }

    return true;
}

