# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.22

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/rohit/minevally

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/rohit/minevally

# Include any dependencies generated for this target.
include CMakeFiles/MineVally.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/MineVally.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/MineVally.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/MineVally.dir/flags.make

CMakeFiles/MineVally.dir/glad.c.o: CMakeFiles/MineVally.dir/flags.make
CMakeFiles/MineVally.dir/glad.c.o: glad.c
CMakeFiles/MineVally.dir/glad.c.o: CMakeFiles/MineVally.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/rohit/minevally/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/MineVally.dir/glad.c.o"
	/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/MineVally.dir/glad.c.o -MF CMakeFiles/MineVally.dir/glad.c.o.d -o CMakeFiles/MineVally.dir/glad.c.o -c /home/rohit/minevally/glad.c

CMakeFiles/MineVally.dir/glad.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/MineVally.dir/glad.c.i"
	/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/rohit/minevally/glad.c > CMakeFiles/MineVally.dir/glad.c.i

CMakeFiles/MineVally.dir/glad.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/MineVally.dir/glad.c.s"
	/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/rohit/minevally/glad.c -o CMakeFiles/MineVally.dir/glad.c.s

CMakeFiles/MineVally.dir/src/callbacks.cpp.o: CMakeFiles/MineVally.dir/flags.make
CMakeFiles/MineVally.dir/src/callbacks.cpp.o: src/callbacks.cpp
CMakeFiles/MineVally.dir/src/callbacks.cpp.o: CMakeFiles/MineVally.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/rohit/minevally/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object CMakeFiles/MineVally.dir/src/callbacks.cpp.o"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/MineVally.dir/src/callbacks.cpp.o -MF CMakeFiles/MineVally.dir/src/callbacks.cpp.o.d -o CMakeFiles/MineVally.dir/src/callbacks.cpp.o -c /home/rohit/minevally/src/callbacks.cpp

CMakeFiles/MineVally.dir/src/callbacks.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/MineVally.dir/src/callbacks.cpp.i"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/rohit/minevally/src/callbacks.cpp > CMakeFiles/MineVally.dir/src/callbacks.cpp.i

CMakeFiles/MineVally.dir/src/callbacks.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/MineVally.dir/src/callbacks.cpp.s"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/rohit/minevally/src/callbacks.cpp -o CMakeFiles/MineVally.dir/src/callbacks.cpp.s

CMakeFiles/MineVally.dir/src/main.cpp.o: CMakeFiles/MineVally.dir/flags.make
CMakeFiles/MineVally.dir/src/main.cpp.o: src/main.cpp
CMakeFiles/MineVally.dir/src/main.cpp.o: CMakeFiles/MineVally.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/rohit/minevally/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object CMakeFiles/MineVally.dir/src/main.cpp.o"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/MineVally.dir/src/main.cpp.o -MF CMakeFiles/MineVally.dir/src/main.cpp.o.d -o CMakeFiles/MineVally.dir/src/main.cpp.o -c /home/rohit/minevally/src/main.cpp

CMakeFiles/MineVally.dir/src/main.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/MineVally.dir/src/main.cpp.i"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/rohit/minevally/src/main.cpp > CMakeFiles/MineVally.dir/src/main.cpp.i

CMakeFiles/MineVally.dir/src/main.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/MineVally.dir/src/main.cpp.s"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/rohit/minevally/src/main.cpp -o CMakeFiles/MineVally.dir/src/main.cpp.s

CMakeFiles/MineVally.dir/src/settings.cpp.o: CMakeFiles/MineVally.dir/flags.make
CMakeFiles/MineVally.dir/src/settings.cpp.o: src/settings.cpp
CMakeFiles/MineVally.dir/src/settings.cpp.o: CMakeFiles/MineVally.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/rohit/minevally/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object CMakeFiles/MineVally.dir/src/settings.cpp.o"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/MineVally.dir/src/settings.cpp.o -MF CMakeFiles/MineVally.dir/src/settings.cpp.o.d -o CMakeFiles/MineVally.dir/src/settings.cpp.o -c /home/rohit/minevally/src/settings.cpp

CMakeFiles/MineVally.dir/src/settings.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/MineVally.dir/src/settings.cpp.i"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/rohit/minevally/src/settings.cpp > CMakeFiles/MineVally.dir/src/settings.cpp.i

CMakeFiles/MineVally.dir/src/settings.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/MineVally.dir/src/settings.cpp.s"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/rohit/minevally/src/settings.cpp -o CMakeFiles/MineVally.dir/src/settings.cpp.s

CMakeFiles/MineVally.dir/src/shader.cpp.o: CMakeFiles/MineVally.dir/flags.make
CMakeFiles/MineVally.dir/src/shader.cpp.o: src/shader.cpp
CMakeFiles/MineVally.dir/src/shader.cpp.o: CMakeFiles/MineVally.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/rohit/minevally/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object CMakeFiles/MineVally.dir/src/shader.cpp.o"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT CMakeFiles/MineVally.dir/src/shader.cpp.o -MF CMakeFiles/MineVally.dir/src/shader.cpp.o.d -o CMakeFiles/MineVally.dir/src/shader.cpp.o -c /home/rohit/minevally/src/shader.cpp

CMakeFiles/MineVally.dir/src/shader.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/MineVally.dir/src/shader.cpp.i"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/rohit/minevally/src/shader.cpp > CMakeFiles/MineVally.dir/src/shader.cpp.i

CMakeFiles/MineVally.dir/src/shader.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/MineVally.dir/src/shader.cpp.s"
	/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/rohit/minevally/src/shader.cpp -o CMakeFiles/MineVally.dir/src/shader.cpp.s

# Object files for target MineVally
MineVally_OBJECTS = \
"CMakeFiles/MineVally.dir/glad.c.o" \
"CMakeFiles/MineVally.dir/src/callbacks.cpp.o" \
"CMakeFiles/MineVally.dir/src/main.cpp.o" \
"CMakeFiles/MineVally.dir/src/settings.cpp.o" \
"CMakeFiles/MineVally.dir/src/shader.cpp.o"

# External object files for target MineVally
MineVally_EXTERNAL_OBJECTS =

MineVally: CMakeFiles/MineVally.dir/glad.c.o
MineVally: CMakeFiles/MineVally.dir/src/callbacks.cpp.o
MineVally: CMakeFiles/MineVally.dir/src/main.cpp.o
MineVally: CMakeFiles/MineVally.dir/src/settings.cpp.o
MineVally: CMakeFiles/MineVally.dir/src/shader.cpp.o
MineVally: CMakeFiles/MineVally.dir/build.make
MineVally: libimgui.a
MineVally: /usr/lib/x86_64-linux-gnu/libglfw.so.3.3
MineVally: /usr/lib/x86_64-linux-gnu/libGLX.so
MineVally: /usr/lib/x86_64-linux-gnu/libOpenGL.so
MineVally: CMakeFiles/MineVally.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/rohit/minevally/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Linking CXX executable MineVally"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/MineVally.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/MineVally.dir/build: MineVally
.PHONY : CMakeFiles/MineVally.dir/build

CMakeFiles/MineVally.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/MineVally.dir/cmake_clean.cmake
.PHONY : CMakeFiles/MineVally.dir/clean

CMakeFiles/MineVally.dir/depend:
	cd /home/rohit/minevally && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/rohit/minevally /home/rohit/minevally /home/rohit/minevally /home/rohit/minevally /home/rohit/minevally/CMakeFiles/MineVally.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/MineVally.dir/depend

