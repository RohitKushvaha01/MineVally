cmake_minimum_required(VERSION 3.10)

# Project name
project(MineVally)

# Set CMP0072 policy to prefer GLVND
if(POLICY CMP0072)
  cmake_policy(SET CMP0072 NEW)
endif()

# Prefer GLVND for OpenGL
set(OpenGL_GL_PREFERENCE GLVND)

# Specify C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE Debug)


# Find OpenGL
find_package(OpenGL REQUIRED)

# Find GLFW
find_package(glfw3 REQUIRED)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Source files
file(GLOB SOURCES 
    ${CMAKE_SOURCE_DIR}/src/*.cpp
    ${CMAKE_SOURCE_DIR}/src/deps/*.cpp
    ${CMAKE_SOURCE_DIR}/src/deps/*.c
    ${CMAKE_SOURCE_DIR}/src/*.c
    ${CMAKE_SOURCE_DIR}/src/ui/*.c
    ${CMAKE_SOURCE_DIR}/src/ui/*.cpp
)

# ImGui setup
set(IMGUI_DIR ${CMAKE_SOURCE_DIR}/src/deps/imgui-1.91.5)

set(IMGUI_SRC
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
    ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
)

add_library(imgui STATIC ${IMGUI_SRC})

# Include ImGui headers
target_include_directories(imgui PUBLIC ${IMGUI_DIR} ${IMGUI_DIR}/backends)

# Add the executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Link libraries
target_link_libraries(${PROJECT_NAME} imgui OpenGL::GL glfw)
