package com.rk.minevally;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Mesh;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.VertexAttribute;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.attributes.TextureAttribute;
import com.badlogic.gdx.graphics.g3d.utils.CameraInputController;
import com.badlogic.gdx.graphics.g3d.utils.MeshBuilder;
import com.badlogic.gdx.graphics.glutils.ShaderProgram;
import com.badlogic.gdx.utils.ScreenUtils;

public class Main extends ApplicationAdapter {

    private PerspectiveCamera camera;
    private CameraInputController cameraController;
    private ShaderProgram shaderProgram;
    private Mesh cubeMesh;
    private TextureAtlas atlas;
    private Texture texture;

    @Override
    public void create() {
        atlas = new TextureAtlas(Gdx.files.internal("atlas.atlas"));
        texture = atlas.getTextures().first(); // All regions share the same texture

        TextureAtlas.AtlasRegion region1 = atlas.findRegion("1");
        TextureAtlas.AtlasRegion region2 = atlas.findRegion("2");
        FileHandle vertexShaderFile = Gdx.files.internal("vert.glsl");
        FileHandle fragmentShaderFile = Gdx.files.internal("frag.glsl");

        String vertexShader = vertexShaderFile.readString();
        String fragmentShader = fragmentShaderFile.readString();

        shaderProgram = new ShaderProgram(vertexShader, fragmentShader);
        if (!shaderProgram.isCompiled()) {
            Gdx.app.error("ShaderProgram", "Compilation failed:\n" + shaderProgram.getLog());
        }

        VertexAttributes attributes = new VertexAttributes(
            VertexAttribute.Position(),
            VertexAttribute.Normal(),
            VertexAttribute.TexCoords(0)
        );

        MeshBuilder meshBuilder = new MeshBuilder();
        meshBuilder.begin(attributes, GL20.GL_TRIANGLES);
        // Front face
        addFace(meshBuilder, -0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, region1);

// Back face
        addFace(meshBuilder, 0.5f, -0.5f, -0.5f, -0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, region2);

// Left face
        addFace(meshBuilder, -0.5f, -0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, -0.5f, region1);

// Right face
        addFace(meshBuilder, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, region2);

// Top face
        addFace(meshBuilder, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f, region1);

// Bottom face
        addFace(meshBuilder, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, -0.5f, -0.5f, 0.5f, region2);

        cubeMesh = meshBuilder.end();

        camera = new PerspectiveCamera(67, Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        camera.position.set(2f, 2f, 2f);
        camera.lookAt(0, 0, 0);
        camera.near = 0.1f;
        camera.far = 300f;
        camera.update();

        cameraController = new CameraInputController(camera);
        Gdx.input.setInputProcessor(cameraController);
    }

    private void addFace(MeshBuilder meshBuilder, float x1, float y1, float z1,
                         float x2, float y2, float z2,
                         float x3, float y3, float z3,
                         float x4, float y4, float z4,
                         TextureAtlas.AtlasRegion region) {
        float u1 = region.getU();
        float v1 = region.getV();
        float u2 = region.getU2();
        float v2 = region.getV2();

        meshBuilder.setUVRange(u1, v1, u2, v2);

        // Calculate normal vector
        float nx = (y2-y1)*(z3-z1) - (z2-z1)*(y3-y1);
        float ny = (z2-z1)*(x3-x1) - (x2-x1)*(z3-z1);
        float nz = (x2-x1)*(y3-y1) - (y2-y1)*(x3-x1);
        float length = (float) Math.sqrt(nx*nx + ny*ny + nz*nz);
        nx /= length;
        ny /= length;
        nz /= length;

        // Define vertices for the face
        meshBuilder.rect(
            x1, y1, z1,   // vertex 1
            x2, y2, z2,   // vertex 2
            x3, y3, z3,   // vertex 3
            x4, y4, z4,   // vertex 4
            nx, ny, nz    // Normal vector
        );
    }



    @Override
    public void render() {
        ScreenUtils.clear(0.53f, 0.81f, 0.92f, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT | GL20.GL_DEPTH_BUFFER_BIT);

        Gdx.gl.glEnable(GL20.GL_DEPTH_TEST);
        Gdx.gl.glDepthFunc(GL20.GL_LEQUAL);

        shaderProgram.bind();
        shaderProgram.setUniformMatrix("u_projTrans", camera.combined);

        texture.bind();
        shaderProgram.setUniformi("u_texture", 0);
        cubeMesh.render(shaderProgram, GL20.GL_TRIANGLES);

        cameraController.update();
    }

    @Override
    public void resize(int width, int height) {
        camera.viewportWidth = width;
        camera.viewportHeight = height;
        camera.update();
    }

    @Override
    public void dispose() {
        cubeMesh.dispose();
        shaderProgram.dispose();
        atlas.dispose();
    }
}
