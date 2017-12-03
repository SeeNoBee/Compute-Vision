include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindDependency.cmake)

find_dependency(
    NAME opencv
    EXPORT_NAME OpenCVConfig.cmake EXPORT_TARGET opencv_core)
