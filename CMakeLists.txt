cmake_minimum_required(VERSION 3.5.0 FATAL_ERROR)

project(ComputerVisionHomework CXX)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

add_executable(ComputerVisionHomework src/main.cpp)

include(FindDependency)

set_dependency_dirs()

set_search_dirs(NAME OpenCV)

find(OpenCV_DIR STATUS
PATHS ${OpenCV_SEARCH_DIRS}
INDICATOR OpenCVModules.cmake
LEVEL 4
DOC "OpenCV export directory")

find_package(OpenCV REQUIRED)

target_link_libraries(ComputerVisionHomework PUBLIC ${OpenCV_LIBS})
