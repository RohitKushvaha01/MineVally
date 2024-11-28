#include "chunk.hpp"
#include <cstring>
#include "deps/OpenSimplex2S.hpp"

Chunk::Chunk() {
    std::memset(chunk, 0, sizeof(chunk));
}

int Chunk::to1DIndex(int x, int y, int z) {
    return x + (y * CHUNK_SIZE) + (z * CHUNK_SIZE * CHUNK_SIZE);
}

uint8_t Chunk::getBlock(int x, int y, int z) {
    if (x < 0 || x >= CHUNK_SIZE || y < 0 || y >= CHUNK_SIZE || z < 0 || z >= CHUNK_SIZE)
        return 0;
    return chunk[to1DIndex(x, y, z)];
}

void Chunk::setBlock(int x, int y, int z, uint8_t value) {
    if (x < 0 || x >= CHUNK_SIZE || y < 0 || y >= CHUNK_SIZE || z < 0 || z >= CHUNK_SIZE)
        return;
    chunk[to1DIndex(x, y, z)] = value;
}

bool Chunk::isFaceVisible(int x, int y, int z, int face) {
    switch (face) {
        case 0: return y >= CHUNK_SIZE - 1 || getBlock(x, y + 1, z) == 0;
        case 1: return y <= 0 || getBlock(x, y - 1, z) == 0;
        case 2: return z >= CHUNK_SIZE - 1 || getBlock(x, y, z + 1) == 0;
        case 3: return z <= 0 || getBlock(x, y, z - 1) == 0;
        case 4: return x <= 0 || getBlock(x - 1, y, z) == 0;
        case 5: return x >= CHUNK_SIZE - 1 || getBlock(x + 1, y, z) == 0;
        default: return false;
    }
}

void Chunk::initialize(int chunkX, int chunkZ) {
    OpenSimplex2S simplex(912778);  // OpenSimplex2S noise generator with seed

    for (int x = 0; x < CHUNK_SIZE; ++x) {
        for (int z = 0; z < CHUNK_SIZE; ++z) {
            float total_noise = 0.0;
            float frequency = 0.05;  // Low frequency for rolling hills
            float amplitude = 1.3;   // Standard amplitude
            int octaves = 2;  // Fewer octaves for smoother terrain

            // Combine multiple octaves of noise for a smoother result
            for (int i = 0; i < octaves; ++i) {
                float worldX = (chunkX * CHUNK_SIZE) + x;
                float worldZ = (chunkZ * CHUNK_SIZE) + z;
                // Generate noise at increasing frequency and decreasing amplitude
                total_noise += simplex.noise2(worldX * frequency, worldZ * frequency) * amplitude;
                frequency *= 2.0;  // Increase frequency
                amplitude *= 0.5;  // Decrease amplitude
            }

            // Normalize and scale the total noise value to get height
            float normalized_noise = (total_noise + 1.0) / 2.0;  // Normalize to [0, 1]
            float height = normalized_noise * (CHUNK_SIZE / 2.0) + (CHUNK_SIZE / 4.0);  // Adjust height range for rolling hills

            // Fill the chunk with blocks based on height
            for (int y = 0; y < CHUNK_SIZE; ++y) {
                if (y < height) {
                    setBlock(x, y, z, 1);  // Solid block below the height (terrain)
                } else {
                    setBlock(x, y, z, 0);  // Air block above the height (sky)
                }
            }
        }
    }
}


void Chunk::generateMesh(std::vector<Vertex>& vertices, std::vector<unsigned int>& indices) {
    vertices.clear();
    indices.clear();
    
    const float faceVertices[6][12] = {
        {-0.5f, 0.5f, -0.5f,  0.5f, 0.5f, -0.5f,  0.5f, 0.5f, 0.5f,  -0.5f, 0.5f, 0.5f},
        {-0.5f, -0.5f, -0.5f,  0.5f, -0.5f, -0.5f,  0.5f, -0.5f, 0.5f,  -0.5f, -0.5f, 0.5f},
        {-0.5f, -0.5f, 0.5f,  0.5f, -0.5f, 0.5f,  0.5f, 0.5f, 0.5f,  -0.5f, 0.5f, 0.5f},
        {-0.5f, -0.5f, -0.5f,  0.5f, -0.5f, -0.5f,  0.5f, 0.5f, -0.5f,  -0.5f, 0.5f, -0.5f},
        {-0.5f, -0.5f, -0.5f,  -0.5f, -0.5f, 0.5f,  -0.5f, 0.5f, 0.5f,  -0.5f, 0.5f, -0.5f},
        {0.5f, -0.5f, -0.5f,  0.5f, -0.5f, 0.5f,  0.5f, 0.5f, 0.5f,  0.5f, 0.5f, -0.5f}
    };

    const float texCoords[8] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f
    };

    vertices.reserve(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * 24);
    indices.reserve(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * 36);

    for (int x = 0; x < CHUNK_SIZE; ++x) {
        for (int y = 0; y < CHUNK_SIZE; ++y) {
            for (int z = 0; z < CHUNK_SIZE; ++z) {

                if (getBlock(x, y, z) != 0) {
                    for (int face = 0; face < 6; ++face) {
                        if (isFaceVisible(x, y, z, face)) {
                            unsigned int indexOffset = vertices.size();
                            
                            for (int v = 0; v < 4; ++v) {
                                Vertex vertex;
                                vertex.position = glm::vec3(
                                    x + faceVertices[face][v * 3],
                                    y + faceVertices[face][v * 3 + 1],
                                    z + faceVertices[face][v * 3 + 2]
                                );
                                vertex.texCoord = glm::vec2(
                                    texCoords[v * 2],
                                    texCoords[v * 2 + 1]
                                );
                                vertices.push_back(vertex);
                            }

                            indices.push_back(indexOffset);
                            indices.push_back(indexOffset + 1);
                            indices.push_back(indexOffset + 2);
                            indices.push_back(indexOffset + 2);
                            indices.push_back(indexOffset + 3);
                            indices.push_back(indexOffset);
                        }
                    }
                }
            }
        }
    }

    vertices.shrink_to_fit();
    indices.shrink_to_fit();
}