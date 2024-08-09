package com.rk.minevally;

import static com.rk.minevally.Chunk.CHUNK_SIZE;

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
import com.badlogic.gdx.graphics.g3d.utils.CameraInputController;
import com.badlogic.gdx.graphics.g3d.utils.MeshBuilder;
import com.badlogic.gdx.graphics.glutils.ShaderProgram;
import com.badlogic.gdx.utils.ScreenUtils;

public class Main extends ApplicationAdapter {

    private PerspectiveCamera camera;
    private CameraInputController cameraController;
    private ShaderProgram shaderProgram;
    //private Mesh cubeMesh;
    Chunk chunk;
    private TextureAtlas atlas;
    private Texture texture;

    @Override
    public void create() {
        atlas = new TextureAtlas(Gdx.files.internal("atlas.atlas"));
        texture = atlas.getTextures().first(); // All regions share the same texture

        FileHandle vertexShaderFile = Gdx.files.internal("vert.glsl");
        FileHandle fragmentShaderFile = Gdx.files.internal("frag.glsl");

        String vertexShader = vertexShaderFile.readString();
        String fragmentShader = fragmentShaderFile.readString();

        shaderProgram = new ShaderProgram(vertexShader, fragmentShader);
        if (!shaderProgram.isCompiled()) {
            Gdx.app.error("ShaderProgram", "Compilation failed:\n" + shaderProgram.getLog());
        }


        //cubeMesh = Block.newBlock(atlas);

        boolean[][][] voxelData = new boolean[CHUNK_SIZE][CHUNK_SIZE][CHUNK_SIZE];


        for (int x = 0; x < CHUNK_SIZE; x++) {
            for (int y = 0; y < CHUNK_SIZE; y++) {
                for (int z = 0; z < CHUNK_SIZE; z++) {
                   // voxelData[x][y][z] = Math.random() > 0.5;
                   voxelData[x][y][z] = true;
                }
            }
        }



        chunk = new Chunk(voxelData,atlas);

        camera = new PerspectiveCamera(67, Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        camera.position.set(2f, 2f, 2f);
        camera.lookAt(0, 0, 0);
        camera.near = 0.1f;
        camera.far = 300f;
        camera.update();

        cameraController = new CameraInputController(camera);
        Gdx.input.setInputProcessor(cameraController);
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
        //cubeMesh.render(shaderProgram, GL20.GL_TRIANGLES);
        chunk.getMesh().render(shaderProgram,GL20.GL_TRIANGLES);

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
       // cubeMesh.dispose();
        shaderProgram.dispose();
        atlas.dispose();
    }
}
