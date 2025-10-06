#include "../deps/imgui-1.91.5/backends/imgui_impl_glfw.h"
#include "../deps/imgui-1.91.5/backends/imgui_impl_opengl3.h"
#include "../deps/imgui-1.91.5/imgui.h"
#include <sys/resource.h>
#include <iostream>
#include <malloc.h>
#include <GLFW/glfw3.h>
#include "../callbacks.h"

#include <fstream>
#include <string>
#include <sstream>


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
    ImFont *customFont = io.Fonts->AddFontFromFileTTF("font.ttf", 18.0f);
    if (customFont == nullptr)
    {
        std::cerr << "Failed to load font!" << std::endl;
    }
    // Upload font texture to GPU
    ImGui_ImplOpenGL3_CreateFontsTexture();
}

 
void renderUi()
{
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
    ImGui::Begin("TextWindow", nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoBackground | ImGuiWindowFlags_NoMove);
    int fps = ImGui::GetIO().Framerate;
    ImGui::Text("FPS : %d",fps);
    ImGui::Text("X : %.2f\nY : %.2f\nZ : %.2f", camera.position.x, camera.position.y, camera.position.z);
    ImGui::Text("HEAP : %dMB",static_cast<int>(mallinfo2().uordblks / (1024.0 * 1024.0)));
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
    if (ImGui::GetCurrentContext() == nullptr) return;
    // Shutdown OpenGL and GLFW implementations for ImGui
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();

    // Destroy the ImGui context and free all associated resources
    ImGui::DestroyContext();
}
