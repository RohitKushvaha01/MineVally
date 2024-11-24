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

# Find OpenGL
find_package(OpenGL REQUIRED)

# Include GLFW
find_package(glfw3 REQUIRED)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Source files
file(GLOB SOURCES 
    ${CMAKE_SOURCE_DIR}/src/*.cpp
    ${CMAKE_SOURCE_DIR}/src/*.c
    ${CMAKE_SOURCE_DIR}/glad.c
)

# Add the executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Link libraries
target_link_libraries(${PROJECT_NAME} OpenGL::GL glfw)
