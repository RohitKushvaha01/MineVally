# Building MineVally

Follow these steps to build and run MineVally on a Debian-based Linux distribution. Ensure the required tools are installed before proceeding.

## Prerequisites

You may need to change paths in the cmakeList.txt

Make sure you have the following installed:

- **CMake**
- **Make**
- **Clang** or **GCC**
- **GLFW**
- **Opengl Library**
- **GLM**

You can install these tools with the following command if they are not already installed:

```bash
sudo apt update && sudo apt install -y cmake make gcc g++
```

## Build Steps

1. Clone the repository (if not already done):
   ```bash
   git clone <repository-url>
   cd MineVally
   ```

2. Generate the build files using CMake:
   ```bash
   cmake .
   ```

3. Clean any previous builds (optional but recommended):
   ```bash
   make clean
   ```

4. Build the project:
   ```bash
   make
   ```

5. Run the application:
   ```bash
   ./MineVally
   ```