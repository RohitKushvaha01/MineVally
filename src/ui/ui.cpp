#include "../deps/imgui-1.91.5/backends/imgui_impl_glfw.h"
#include "../deps/imgui-1.91.5/backends/imgui_impl_opengl3.h"
#include "../deps/imgui-1.91.5/imgui.h"
#include <iostream>
#include <GLFW/glfw3.h>

void initUi(GLFWwindow *window)
{
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO();
    (void)io;
    ImGui::StyleColorsDark(); // or ImGui::StyleColorsClassic() or ImGui::StyleColorsLight()

    // Initialize ImGui for GLFW and OpenGL
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    // Replace "Roboto-Regular.ttf" with your font path and size
    ImFont *customFont = io.Fonts->AddFontFromFileTTF("/home/rohit/minevally/font.ttf", 18.0f);
    if (customFont == nullptr)
    {
        std::cerr << "Failed to load font!" << std::endl;
    }
    // Upload font texture to GPU
    ImGui_ImplOpenGL3_CreateFontsTexture();
}

float lastTime = 0.0f; // Last time the frame was rendered
int frameCount = 0;    // Number of frames rendered
int fps = 0;      // FPS value

void renderUi()
{
    float currentTime = glfwGetTime(); // Get the current time
    frameCount++;                      // Increment frame count

    // Calculate FPS every second (or time period of your choice)
    if (currentTime - lastTime >= 1.0f)
    {
        fps = frameCount / (currentTime - lastTime); // Calculate FPS
        lastTime = currentTime;                      // Reset last time
        frameCount = 0;                              // Reset frame count
    }

    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    // Use custom font
    ImFont *customFont = ImGui::GetIO().Fonts->Fonts[0]; // Assuming it's the first loaded font
    if (customFont)
    {
        ImGui::PushFont(customFont); // Use the custom font
    }

    // Draw text
    ImGui::SetNextWindowPos(ImVec2(10, 10), ImGuiCond_Always); // Position the text
    ImGui::Begin("TextWindow", nullptr, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoBackground | ImGuiWindowFlags_NoMove);
    ImGui::Text("fps : %d",fps);
    ImGui::End();

    if (customFont)
    {
        ImGui::PopFont(); // Restore the default font
    }

    ImGui::Render();
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

void disposeUi()
{
    // Shutdown OpenGL and GLFW implementations for ImGui
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();

    // Destroy the ImGui context and free all associated resources
    ImGui::DestroyContext();
}
