#pragma once
#include <vector>
#include <cstdint>
#include <glm/glm.hpp>

const int CHUNK_SIZE = 16;

struct Vertex {
    glm::vec3 position;
    glm::vec2 texCoord;
};

class Chunk {
private:
    uint8_t chunk[CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE];
    
    int to1DIndex(int x, int y, int z);
    bool isFaceVisible(int x, int y, int z, int face);

    
public:
    Chunk();
    uint8_t getBlock(int x, int y, int z);
    void setBlock(int x, int y, int z, uint8_t value);
    void initialize(int chunkX, int chunkZ);
    void generateMesh(std::vector<Vertex>& vertices, std::vector<unsigned int>& indices);
};