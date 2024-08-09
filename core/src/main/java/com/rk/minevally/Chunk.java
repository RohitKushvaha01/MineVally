package com.rk.minevally;

import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Mesh;
import com.badlogic.gdx.graphics.VertexAttribute;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g3d.utils.MeshBuilder;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.math.Vector3;

public class Chunk {
    static final int CHUNK_SIZE = 16; // Define your chunk size here
    static final int CHUNK_HEIGHT = 64;
    private final boolean[][][] voxelData;
    private Mesh mesh;

    public Chunk(boolean[][][] voxelData, TextureAtlas atlas) {
        this.voxelData = voxelData;
        generateMesh(atlas);
    }

    public Mesh getMesh() {
        return mesh;
    }

    private void generateMesh(TextureAtlas atlas) {
        VertexAttributes attributes = new VertexAttributes(
            VertexAttribute.Position(),
            VertexAttribute.Normal(),
            VertexAttribute.TexCoords(0)
        );

        MeshBuilder meshBuilder = new MeshBuilder();
        meshBuilder.begin(attributes, GL20.GL_TRIANGLES);

        for (int x = 0; x < CHUNK_SIZE; x++) {
            for (int y = 0; y < CHUNK_HEIGHT; y++) {
                for (int z = 0; z < CHUNK_SIZE; z++) {
                    if (voxelData[x][y][z]) {
                        Matrix4 transform = new Matrix4().setToTranslation(new Vector3(x, y, z));

                        // Check neighbors to skip faces that are adjacent to other blocks
                        if (x == 0 || !voxelData[x - 1][y][z]) { // Left face
                            meshBuilder.setVertexTransform(transform);
                            Block.addLeftFace(meshBuilder, atlas);
                        }
                        if (x == CHUNK_SIZE - 1 || !voxelData[x + 1][y][z]) { // Right face
                            meshBuilder.setVertexTransform(transform);
                            Block.addRightFace(meshBuilder, atlas);
                        }
                        if (y == 0 || !voxelData[x][y - 1][z]) { // Bottom face
                            meshBuilder.setVertexTransform(transform);
                            Block.addBottomFace(meshBuilder, atlas);
                        }
                        if (y == CHUNK_HEIGHT - 1 || !voxelData[x][y + 1][z]) { // Top face
                            meshBuilder.setVertexTransform(transform);
                            Block.addTopFace(meshBuilder, atlas);
                        }
                        if (z == 0 || !voxelData[x][y][z - 1]) { // Back face
                            meshBuilder.setVertexTransform(transform);
                            Block.addBackFace(meshBuilder, atlas);
                        }
                        if (z == CHUNK_SIZE - 1 || !voxelData[x][y][z + 1]) { // Front face
                            meshBuilder.setVertexTransform(transform);
                            Block.addFrontFace(meshBuilder, atlas);
                        }
                    }
                }
            }
        }

        mesh = meshBuilder.end();
    }
}
