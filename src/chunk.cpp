#include "chunk.hpp"
#include <cstring>
#include "deps/OpenSimplex2S.hpp"

Chunk::Chunk()
{
    std::memset(chunk, 0, sizeof(chunk));
}

int Chunk::to1DIndex(int x, int y, int z)
{
    return x + (y * CHUNK_SIZE) + (z * CHUNK_SIZE * CHUNK_SIZE);
}

uint8_t Chunk::getBlock(int x, int y, int z)
{
    if (x < 0 || x >= CHUNK_SIZE || y < 0 || y >= CHUNK_SIZE || z < 0 || z >= CHUNK_SIZE)
        return 0;
    return chunk[to1DIndex(x, y, z)];
}

void Chunk::setBlock(int x, int y, int z, uint8_t value)
{
    if (x < 0 || x >= CHUNK_SIZE || y < 0 || y >= CHUNK_SIZE || z < 0 || z >= CHUNK_SIZE)
        return;
    chunk[to1DIndex(x, y, z)] = value;
}

bool Chunk::isFaceVisible(int x, int y, int z, int face)
{
    switch (face)
    {
    case 0:
        return y >= CHUNK_SIZE - 1 || getBlock(x, y + 1, z) == 0;
    case 1:
        return y <= 0 || getBlock(x, y - 1, z) == 0;
    case 2:
        return z >= CHUNK_SIZE - 1 || getBlock(x, y, z + 1) == 0;
    case 3:
        return z <= 0 || getBlock(x, y, z - 1) == 0;
    case 4:
        return x <= 0 || getBlock(x - 1, y, z) == 0;
    case 5:
        return x >= CHUNK_SIZE - 1 || getBlock(x + 1, y, z) == 0;
    default:
        return false;
    }
}

void Chunk::initialize(int chunkX, int chunkY, int chunkZ)
{
    OpenSimplex2S simplex(912778); // Noise generator with seed

    for (int x = 0; x < CHUNK_SIZE; ++x)
    {
        for (int z = 0; z < CHUNK_SIZE; ++z)
        {
            float total_noise = 0.0f;
            float frequency = 0.01f; // lower = smoother hills
            float amplitude = 1.0f;
            int octaves = 4;

            // World coordinates for x,z
            float worldX = (chunkX * CHUNK_SIZE) + x;
            float worldZ = (chunkZ * CHUNK_SIZE) + z;

            // Fractal 2D noise → heightmap
            for (int i = 0; i < octaves; i++)
            {
                total_noise += simplex.noise2(
                                   worldX * frequency,
                                   worldZ * frequency) *
                               amplitude;

                frequency *= 2.0f;
                amplitude *= 0.5f;
            }

            // Normalize
            float normalized = (total_noise + 1.0f) / 2.0f;

            int baseHeight = 64;
            int hillHeight = 48;

            int surfaceHeight = baseHeight + (int)(normalized * hillHeight);

            for (int y = 0; y < CHUNK_SIZE; ++y)
            {
                int worldY = chunkY * CHUNK_SIZE + y;
                if (worldY <= surfaceHeight)
                {
                    float caveNoise = simplex.noise3_Classic(worldX * 0.05f, worldY * 0.05f, worldZ * 0.05f);
                    bool solid = caveNoise > 0.3f;

                    if (solid)
                    {
                        if (worldY == surfaceHeight)
                            setBlock(x, y, z, 1);
                        else if (worldY > surfaceHeight - 4)
                            setBlock(x, y, z, 1);
                        else
                            setBlock(x, y, z, 1);
                    }
                    else
                    {
                        setBlock(x, y, z, 1);
                    }
                }
                else
                {
                    setBlock(x, y, z, 0);
                }
            }
        }
    }
}

bool Chunk::hasBlock(int x, int y, int z)
{
    return getBlock(x, y, z) != 0;
}

float vertexAO(bool side1, bool side2, bool corner)
{
    if (side1 && side2)
    {
        return 0.0f; // Fully occluded
    }
    return 3.0f - (side1 + side2 + corner); // Calculate AO level
}

float Chunk::getVertexAO(int x, int y, int z, int face, int vert)
{
    bool side1 = false, side2 = false, corner = false;

    switch (face)
    {
    case 0: // Top face (+Y)
        switch (vert)
        {
        case 0: // Front-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x - 1, y, z - 1);
            break;
        case 1: // Front-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x + 1, y, z - 1);
            break;
        case 2: // Back-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x + 1, y, z + 1);
            break;
        case 3: // Back-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x - 1, y, z + 1);
            break;
        }
        break;

    case 1: // Bottom face (-Y)
        switch (vert)
        {
        case 0: // Front-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x - 1, y, z - 1);
            break;
        case 1: // Front-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x + 1, y, z - 1);
            break;
        case 2: // Back-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x + 1, y, z + 1);
            break;
        case 3: // Back-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x - 1, y, z + 1);
            break;
        }
        break;

    case 2: // Front face (+Z)
        switch (vert)
        {
        case 0: // Bottom-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y - 1, z);
            corner = hasBlock(x - 1, y - 1, z);
            break;
        case 1: // Bottom-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y - 1, z);
            corner = hasBlock(x + 1, y - 1, z);
            break;
        case 2: // Top-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y + 1, z);
            corner = hasBlock(x + 1, y + 1, z);
            break;
        case 3: // Top-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y + 1, z);
            corner = hasBlock(x - 1, y + 1, z);
            break;
        }
        break;

    case 3: // Back face (-Z)
        switch (vert)
        {
        case 0: // Bottom-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y - 1, z);
            corner = hasBlock(x - 1, y - 1, z);
            break;
        case 1: // Bottom-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y - 1, z);
            corner = hasBlock(x + 1, y - 1, z);
            break;
        case 2: // Top-Right
            side1 = hasBlock(x + 1, y, z);
            side2 = hasBlock(x, y + 1, z);
            corner = hasBlock(x + 1, y + 1, z);
            break;
        case 3: // Top-Left
            side1 = hasBlock(x - 1, y, z);
            side2 = hasBlock(x, y + 1, z);
            corner = hasBlock(x - 1, y + 1, z);
            break;
        }
        break;

    case 4: // Left face (-X)
        switch (vert)
        {
        case 0: // Bottom-Back
            side1 = hasBlock(x, y - 1, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x, y - 1, z - 1);
            break;
        case 1: // Bottom-Front
            side1 = hasBlock(x, y - 1, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x, y - 1, z + 1);
            break;
        case 2: // Top-Front
            side1 = hasBlock(x, y + 1, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x, y + 1, z + 1);
            break;
        case 3: // Top-Back
            side1 = hasBlock(x, y + 1, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x, y + 1, z - 1);
            break;
        }
        break;

    case 5: // Right face (+X)
        switch (vert)
        {
        case 0: // Bottom-Back
            side1 = hasBlock(x, y - 1, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x, y - 1, z - 1);
            break;
        case 1: // Bottom-Front
            side1 = hasBlock(x, y - 1, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x, y - 1, z + 1);
            break;
        case 2: // Top-Front
            side1 = hasBlock(x, y + 1, z);
            side2 = hasBlock(x, y, z + 1);
            corner = hasBlock(x, y + 1, z + 1);
            break;
        case 3: // Top-Back
            side1 = hasBlock(x, y + 1, z);
            side2 = hasBlock(x, y, z - 1);
            corner = hasBlock(x, y + 1, z - 1);
            break;
        }
        break;
    }

    return vertexAO(side1, side2, corner);
}

void Chunk::generateMesh(std::vector<Vertex> &vertices, std::vector<unsigned int> &indices)
{
    vertices.clear();
    indices.clear();

    const float faceVertices[6][12] = {
        {-0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f},
        {-0.5f, -0.5f, -0.5f, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, -0.5f, -0.5f, 0.5f},
        {-0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f},
        {-0.5f, -0.5f, -0.5f, 0.5f, -0.5f, -0.5f, 0.5f, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f},
        {-0.5f, -0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, -0.5f},
        {0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, -0.5f}};

    const float texCoords[8] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f};

    vertices.reserve(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * 24);
    indices.reserve(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * 36);

    for (int x = 0; x < CHUNK_SIZE; ++x)
    {
        for (int y = 0; y < CHUNK_SIZE; ++y)
        {
            for (int z = 0; z < CHUNK_SIZE; ++z)
            {

                if (getBlock(x, y, z) != 0)
                {
                    for (int face = 0; face < 6; ++face)
                    {
                        if (isFaceVisible(x, y, z, face))
                        {
                            unsigned int indexOffset = vertices.size();

                            for (int v = 0; v < 4; ++v)
                            {
                                Vertex vertex;
                                vertex.position = glm::vec3(
                                    x + faceVertices[face][v * 3],
                                    y + faceVertices[face][v * 3 + 1],
                                    z + faceVertices[face][v * 3 + 2]);
                                vertex.texCoord = glm::vec2(
                                    texCoords[v * 2],
                                    texCoords[v * 2 + 1]);

                                vertex.ao = getVertexAO(x, y, z, face, v);

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