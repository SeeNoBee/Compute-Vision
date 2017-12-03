cmake_minimum_required(VERSION 3.5.0 FATAL_ERROR)

project(ComputerVisionHomework CXX)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

add_executable(ComputerVisionHomework src/main.cpp)

include(FindDependency)

set_dependency_dirs()

find_package(opencv COMPONENTS core imgproc highgui REQUIRED)

target_link_libraries(ComputerVisionHomework PUBLIC opencv_core opencv_imgproc opencv_highgui)
