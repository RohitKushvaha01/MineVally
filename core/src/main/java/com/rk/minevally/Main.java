package com.rk.minevally;

import static com.rk.minevally.Chunk.CHUNK_HEIGHT;
import static com.rk.minevally.Chunk.CHUNK_SIZE;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Mesh;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g3d.utils.CameraInputController;
import com.badlogic.gdx.graphics.glutils.ShaderProgram;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.utils.ScreenUtils;

public class Main extends ApplicationAdapter {

    private static final int CHUNK_COUNT_X = 8; // Number of chunks in the X direction
    private static final int CHUNK_COUNT_Z = 8; // Number of chunks in the Z direction

    private PerspectiveCamera camera;
    private CameraInputController cameraController;
    private ShaderProgram shaderProgram;
    private TextureAtlas atlas;
    private Texture texture;
    private Chunk[][] chunks; // 2D array to hold multiple chunks

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

        chunks = new Chunk[CHUNK_COUNT_X][CHUNK_COUNT_Z]; // Initialize the chunk array

        float waveFrequency = 0.1f;  // Controls the frequency of the sine wave
        float amplitude = 10.0f;     // Controls the height variation of the sine wave
        int baseHeight = 32;         // Base height to add to the sine wave, can be half of CHUNK_HEIGHT

        for (int chunkX = 0; chunkX < CHUNK_COUNT_X; chunkX++) {
            for (int chunkZ = 0; chunkZ < CHUNK_COUNT_Z; chunkZ++) {
                boolean[][][] voxelData = new boolean[CHUNK_SIZE][CHUNK_HEIGHT][CHUNK_SIZE];

                for (int x = 0; x < CHUNK_SIZE; x++) {
                    for (int z = 0; z < CHUNK_SIZE; z++) {
                        int globalX = x + chunkX * CHUNK_SIZE;
                        int globalZ = z + chunkZ * CHUNK_SIZE;

                        // Generate surface height using a sine wave function
                        double surfaceHeight = baseHeight + Math.sin(globalX * waveFrequency) * amplitude
                            + Math.sin(globalZ * waveFrequency) * amplitude;

                        // Convert the surface height to an integer and clamp it within the valid range
                        int terrainHeight = Math.min(Math.max((int) surfaceHeight, 0), CHUNK_HEIGHT - 1);

                        // Fill blocks below the surface to create solid terrain
                        for (int y = 0; y <= terrainHeight; y++) {
                            voxelData[x][y][z] = true;
                        }
                    }
                }

                chunks[chunkX][chunkZ] = new Chunk(voxelData, atlas);
            }
        }

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

        for (int chunkX = 0; chunkX < CHUNK_COUNT_X; chunkX++) {
            for (int chunkZ = 0; chunkZ < CHUNK_COUNT_Z; chunkZ++) {
                // Calculate the world position for this chunk
                float worldX = chunkX * CHUNK_SIZE;
                float worldZ = chunkZ * CHUNK_SIZE;

                // Set the model matrix to translate the chunk to its world position
                shaderProgram.setUniformMatrix("u_modelTrans", new Matrix4().setToTranslation(worldX, 0, worldZ));

                // Render the chunk
                chunks[chunkX][chunkZ].getMesh().render(shaderProgram, GL20.GL_TRIANGLES);
            }
        }

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
        shaderProgram.dispose();
        atlas.dispose();
        // Dispose all chunk meshes
        for (int chunkX = 0; chunkX < CHUNK_COUNT_X; chunkX++) {
            for (int chunkZ = 0; chunkZ < CHUNK_COUNT_Z; chunkZ++) {
                chunks[chunkX][chunkZ].getMesh().dispose();
            }
        }
    }
}
