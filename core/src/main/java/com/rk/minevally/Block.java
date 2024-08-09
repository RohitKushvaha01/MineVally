package com.rk.minevally;

import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Mesh;
import com.badlogic.gdx.graphics.VertexAttribute;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g3d.utils.MeshBuilder;

public class Block {

    public static void addFrontFace(MeshBuilder meshBuilder, TextureAtlas atlas) {
        TextureAtlas.AtlasRegion region = atlas.findRegion("1");
        addFace(meshBuilder, -0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, region);
    }

    public static void addBackFace(MeshBuilder meshBuilder, TextureAtlas atlas) {
        TextureAtlas.AtlasRegion region = atlas.findRegion("2");
        addFace(meshBuilder, 0.5f, -0.5f, -0.5f, -0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, region);
    }

    public static void addLeftFace(MeshBuilder meshBuilder, TextureAtlas atlas) {
        TextureAtlas.AtlasRegion region = atlas.findRegion("1");
        addFace(meshBuilder, -0.5f, -0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, -0.5f, region);
    }

    public static void addRightFace(MeshBuilder meshBuilder, TextureAtlas atlas) {
        TextureAtlas.AtlasRegion region = atlas.findRegion("2");
        addFace(meshBuilder, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, region);
    }

    public static void addTopFace(MeshBuilder meshBuilder, TextureAtlas atlas) {
        TextureAtlas.AtlasRegion region = atlas.findRegion("1");
        addFace(meshBuilder, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f, region);
    }

    public static void addBottomFace(MeshBuilder meshBuilder, TextureAtlas atlas) {
        TextureAtlas.AtlasRegion region = atlas.findRegion("2");
        addFace(meshBuilder, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, -0.5f, -0.5f, 0.5f, region);
    }

    private static void addFace(MeshBuilder meshBuilder, float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3, float x4, float y4, float z4, TextureAtlas.AtlasRegion region) {
        float u1 = region.getU();
        float v1 = region.getV();
        float u2 = region.getU2();
        float v2 = region.getV2();

        meshBuilder.setUVRange(u1, v1, u2, v2);

        // Calculate normal vector
        float nx = (y2 - y1) * (z3 - z1) - (z2 - z1) * (y3 - y1);
        float ny = (z2 - z1) * (x3 - x1) - (x2 - x1) * (z3 - z1);
        float nz = (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1);
        float length = (float) Math.sqrt(nx * nx + ny * ny + nz * nz);
        nx /= length;
        ny /= length;
        nz /= length;

        // Define vertices for the face
        meshBuilder.rect(x1, y1, z1,   // vertex 1
            x2, y2, z2,   // vertex 2
            x3, y3, z3,   // vertex 3
            x4, y4, z4,   // vertex 4
            nx, ny, nz    // Normal vector
        );
    }
}
