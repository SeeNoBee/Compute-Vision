include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/functions.cmake)

macro(set_dependency_dirs)
    set(DEPENDENCIES_DIRS_DESCR "Dependencies search directories")
    set(DEPENDENCIES_SRC_DIRS_DESCR "Dependencies sources search directories")

    option(DEPENDENCIES_USE_LIB_DIR "" ON)
    option(DEPENDENCIES_USE_SRC_DIR "" ON)
    option(DEPENDENCIES_USE_3RDPARTY_DIR "" OFF)

    paths_are_exists(DEPENDENCIES_DIRS_EXISTS PATHS "${DEPENDENCIES_DIRS}")

    if(NOT DEPENDENCIES_DIRS_EXISTS)
        set(DEPENDENCIES_DIRS_TMP "")
        if(EXISTS "${CMAKE_SOURCE_DIR}/3rdparty" AND DEPENDENCIES_USE_3RDPARTY_DIR)
            list(APPEND DEPENDENCIES_DIRS_TMP ${CMAKE_SOURCE_DIR}/3rdparty)
            set(DEPENDENCIES_DIRS_EXISTS TRUE)
        endif()
        if(EXISTS "$ENV{LIB_DIR}" AND DEPENDENCIES_USE_LIB_DIR)
            list(APPEND DEPENDENCIES_DIRS_TMP $ENV{LIB_DIR})
            set(DEPENDENCIES_DIRS_EXISTS TRUE)
        endif()
    endif()

    if(DEPENDENCIES_DIRS_EXISTS)
        set(DEPENDENCIES_DIRS ${DEPENDENCIES_DIRS_TMP} CACHE STRING ${DEPENDENCIES_DIRS_DESCR} FORCE)
    else()
        set(DEPENDENCIES_DIRS DEPENDENCIES_DIRS-NOTFOUND CACHE STRING ${DEPENDENCIES_DIRS_DESCR} FORCE)
    endif()

    paths_are_exists(DEPENDENCIES_SRC_DIRS_EXISTS PATHS "${DEPENDENCIES_SRC_DIRS}")

    if(NOT DEPENDENCIES_SRC_DIRS_EXISTS)
        set(DEPENDENCIES_SRC_DIRS_TMP "")
        if(EXISTS "${CMAKE_SOURCE_DIR}/3rdparty" AND DEPENDENCIES_USE_3RDPARTY_DIR)
            list(APPEND DEPENDENCIES_SRC_DIRS_TMP ${CMAKE_SOURCE_DIR}/3rdparty)
            set(DEPENDENCIES_SRC_DIRS_EXISTS TRUE)
        endif()
        if(EXISTS "$ENV{SRC_DIR}" AND DEPENDENCIES_USE_SRC_DIR)
            list(APPEND DEPENDENCIES_SRC_DIRS_TMP $ENV{SRC_DIR})
            set(DEPENDENCIES_SRC_DIRS_EXISTS TRUE)
        endif()
    endif()

    if(DEPENDENCIES_SRC_DIRS_EXISTS)
        set(DEPENDENCIES_SRC_DIRS ${DEPENDENCIES_SRC_DIRS_TMP} CACHE STRING ${DEPENDENCIES_SRC_DIRS_DESCR} FORCE)
    else()
        set(DEPENDENCIES_SRC_DIRS DEPENDENCIES_SRC_DIRS-NOTFOUND CACHE STRING ${DEPENDENCIES_SRC_DIRS_DESCR} FORCE)
    endif()
endmacro(set_dependency_dirs)

macro(set_search_dirs)
    set(options "")
    set(oneValueArgs NAME)
    set(multiValueArgs "")

    parse_arguments("set_search_dirs" "ARGS" ${ARGN})

    set(${ARGS_NAME}_ROOT_DIR_DESCR "${ARGS_NAME} root dir")

    paths_are_exists(DEPENDENCIES_DIRS_EXISTS PATHS "${DEPENDENCIES_DIRS}")
    set(${ARGS_NAME}_SEARCH_DIRS "")

    if(EXISTS "${${ARGS_NAME}_ROOT_DIR}")
        set(${ARGS_NAME}_ROOT_DIR ${${ARGS_NAME}_ROOT_DIR} CACHE PATH ${${ARGS_NAME}_ROOT_DIR_DESCR} FORCE)
        list(APPEND ${ARGS_NAME}_SEARCH_DIRS ${${ARGS_NAME}_ROOT_DIR})
    else()
        if(EXISTS "$ENV{${ARGS_NAME}_DIR}")
            set(${ARGS_NAME}_ROOT_DIR $ENV{${ARGS_NAME}_DIR} CACHE PATH ${${ARGS_NAME}_ROOT_DIR_DESCR} FORCE)
        else()
            set(${ARGS_NAME}_ROOT_DIR "" CACHE PATH ${${ARGS_NAME}_ROOT_DIR_DESCR} FORCE)
        endif()
    endif()

    if(EXISTS "$ENV{${ARGS_NAME}_DIR}")
        list(APPEND ${ARGS_NAME}_SEARCH_DIRS $ENV{${ARGS_NAME}_DIR})
    endif()

    if(DEPENDENCIES_DIRS_EXISTS)
        foreach(PATH ${DEPENDENCIES_DIRS})
            foreach(HINT ${ARGS_HINTS})
                add_to_path(PATH_WITH_HINT "${PATH}" "${HINT}")
                if(EXISTS "${PATH_WITH_HINT}")
                    list(APPEND ${ARGS_NAME}_SEARCH_DIRS "${PATH_WITH_HINT}")
                endif()
            endforeach()
        endforeach()
        list(APPEND ${ARGS_NAME}_SEARCH_DIRS ${DEPENDENCIES_DIRS})
    endif()
endmacro(set_search_dirs)

macro(create_target NAME)
    is_found(${NAME}_LIBRARY_FOUND "${${NAME}_LIBRARY}")
    is_found(${NAME}_RUNTIME_FOUND "${${NAME}_RUNTIME}")

    if(ARGS_HEADERONLY OR NOT ${NAME}_LIBRARY_FOUND)
        set(TARGET INTERFACE)
    elseif(ARGS_STATIC OR NOT ${NAME}_RUNTIME_FOUND)
        set(TARGET STATIC)
    else()
        set(TARGET SHARED)
    endif()

    add_library(${ARGS_EXPORT_TARGET} ${TARGET} IMPORTED)

    set_target_properties(${ARGS_EXPORT_TARGET} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${${NAME}_INCLUDE_DIR}")

    if(NOT ARGS_HEADERONLY AND ${NAME}_LIBRARY_FOUND)
        set_property(TARGET ${ARGS_EXPORT_TARGET} APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE)
        set_target_properties(${ARGS_EXPORT_TARGET} PROPERTIES
            IMPORTED_IMPLIB_RELEASE "${${NAME}_LIBRARY}")

        is_found(${NAME}_DEBUG_LIBRARY_FOUND "${${NAME}_DEBUG_LIBRARY}")
        if(${NAME}_DEBUG_LIBRARY_FOUND)
            set_property(TARGET ${ARGS_EXPORT_TARGET} APPEND PROPERTY
                IMPORTED_CONFIGURATIONS DEBUG)
            set_target_properties(${ARGS_EXPORT_TARGET} PROPERTIES
                IMPORTED_IMPLIB_DEBUG "${${NAME}_DEBUG_LIBRARY}")
        endif()

        if(NOT ARGS_STATIC AND ${NAME}_RUNTIME_FOUND)
            set_target_properties(${ARGS_EXPORT_TARGET} PROPERTIES
                IMPORTED_LOCATION_RELEASE "${${NAME}_RUNTIME}")

            is_found(${NAME}_DEBUG_RUNTIME_FOUND "${${NAME}_DEBUG_RUNTIME}")
            if(${NAME}_DEBUG_RUNTIME_FOUND)
                set_target_properties(${ARGS_EXPORT_TARGET} PROPERTIES
                    IMPORTED_LOCATION_DEBUG "${${NAME}_DEBUG_RUNTIME}")
            endif()
        endif()

        get_target_property(${NAME}_CONFIGURATIONS ${ARGS_EXPORT_TARGET} IMPORTED_CONFIGURATIONS)
        message(STATUS "Found ${NAME}: ${TARGET} [${${NAME}_CONFIGURATIONS}]")
    else()
        message(STATUS "Found ${NAME}: ${TARGET}")
    endif()
endmacro(create_target)

macro(find_export)
    find(${ARGS_NAME}_EXPORT_FILE STATUS DEBUG
        PATHS ${${ARGS_NAME}_SEARCH_DIRS}
        INDICATOR ${ARGS_EXPORT_NAME}
        DOC "${ARGS_NAME} export file")
    is_found(${ARGS_NAME}_EXPORT_FILE_FOUND "${${ARGS_NAME}_EXPORT_FILE}")

    if(${ARGS_NAME}_EXPORT_FILE_FOUND)
        find_package_handle_standard_args(${ARGS_NAME}
            FOUND_VAR ${ARGS_NAME}_FOUND
            REQUIRED_VARS ${ARGS_NAME}_EXPORT_FILE)

        include(${${ARGS_NAME}_EXPORT_FILE})

        if(TARGET ${ARGS_EXPORT_TARGET})
            message(STATUS "Found ${ARGS_NAME}: EXPORTFILE")
            unset(${ARGS_MNAME}_INCLUDE_DIR CACHE)
            unset(${ARGS_NAME}_LIBRARY CACHE)
            unset(${ARGS_NAME}_DEBUG_LIBRARY CACHE)
            unset(${ARGS_NAME}_RUNTIME CACHE)
            unset(${ARGS_NAME}_DEBUG_RUNTIME CACHE)
            unset(${ARGS_NAME}_CMAKE_FILE CACHE)
            return()
        endif()
    endif()

    unset(${ARGS_NAME}_EXPORT_FILE CACHE)
endmacro(find_export)

macro(find_src)
    paths_are_exists(DEPENDENCIES_SRC_DIRS_EXISTS PATHS "${DEPENDENCIES_SRC_DIRS}")
    set(${ARGS_NAME}_SRC_SEARCH_DIRS "")
    if(DEPENDENCIES_SRC_DIRS_EXISTS)
        foreach(PATH ${DEPENDENCIES_SRC_DIRS})
            foreach(HINT ${ARGS_HINTS})
                add_to_path(PATH_WITH_HINT "${PATH}" "${HINT}")
                if(EXISTS "${PATH_WITH_HINT}")
                    list(APPEND ${ARGS_NAME}_SRC_SEARCH_DIRS "${PATH_WITH_HINT}")
                endif()
            endforeach()
        endforeach()
        list(APPEND ${ARGS_NAME}_SRC_SEARCH_DIRS "${DEPENDENCIES_SRC_DIRS}")
    endif()

    find(${ARGS_NAME}_CMAKE_FILE STATUS DEBUG
        PATHS ${${ARGS_NAME}_SRC_SEARCH_DIRS}
        INDICATOR ${ARGS_CMAKE_INDICATOR}
        LEVEL ${ARGS_CMAKE_LEVEL}
        DOC "${ARGS_NAME} CMakeLists.txt file")

    if(EXISTS ${${ARGS_NAME}_CMAKE_FILE}/CMakeLists.txt)
        message(STATUS "Found ${ARGS_NAME}: SOURCE")
        add_subdirectory(${${ARGS_NAME}_CMAKE_FILE} ${ARGS_NAME})
        set(${ARGS_NAME}_CMAKE_FILE ${${ARGS_NAME}_CMAKE_FILE}/CMakeLists.txt CACHE FILEPATH "${ARGS_NAME} CMakeLists.txt file" FORCE)

        unset(${ARGS_MNAME}_INCLUDE_DIR CACHE)
        unset(${ARGS_NAME}_LIBRARY CACHE)
        unset(${ARGS_NAME}_DEBUG_LIBRARY CACHE)
        unset(${ARGS_NAME}_RUNTIME CACHE)
        unset(${ARGS_NAME}_DEBUG_RUNTIME CACHE)
        unset(${ARGS_NAME}_EXPORT_FILE CACHE)
    else()
        set(${ARGS_NAME}_CMAKE_FILE ${ARGS_NAME}_CMAKE_FILE-NOTFOUND CACHE FILEPATH "${ARGS_NAME} CMakeLists.txt file" FORCE)
    endif()

    find_package_handle_standard_args(${ARGS_NAME}
        FOUND_VAR ${ARGS_NAME}_FOUND
        REQUIRED_VARS ${ARGS_NAME}_CMAKE_FILE)

    return()
endmacro(find_src)

function(find_dependency)
    set(oneValueArgs
        NAME
        LIBNAME RUNTIMENAME
        DLIBNAME DRUNTIMENAME
        INCLUDE_INDICATOR INCLUDE_LEVEL
        CMAKE_INDICATOR CMAKE_LEVEL
        EXPORT_NAME EXPORT_TARGET
        ROOT_LEVEL)
    set(multiValueArgs HINTS)
    # TODO: set(multiValueArgs ADDITIONAL_DEPENDENCIES)
    set(options HEADERONLY STATIC SRC)

    parse_arguments("find_dependency" "ARGS" ${ARGN})

    message(STATUS "Searching ${ARGS_NAME}")

    if("${ARGS_HINTS}" STREQUAL "")
        set(ARGS_HINTS ${ARGS_NAME})
    endif()

    include(FindPackageHandleStandardArgs)

    set_search_dirs(NAME ${ARGS_NAME})

    option(${ARGS_NAME}_SEARCH_SRC "Search only source files and 'CMakeLists.txt'" ${ARGS_SRC})

    if(${ARGS_NAME}_SEARCH_SRC)
        find_src()
    endif()

    unset(${ARGS_NAME}_CMAKE_FILE CACHE)

    find_export()

    find(${ARGS_NAME}_INCLUDE_DIR STATUS DEBUG
        PATHS ${${ARGS_NAME}_SEARCH_DIRS}
        INDICATOR ${ARGS_INCLUDE_INDICATOR}
        LEVEL ${ARGS_INCLUDE_LEVEL}
        DOC "${ARGS_NAME} include directory")

    if(NOT "${ARGS_ROOT_LEVEL}" STREQUAL "")
        parent(${ARGS_NAME}_ROOT_DIR_TMP PATH ${${ARGS_NAME}_INCLUDE_DIR} LEVEL ${ARGS_ROOT_LEVEL})
        set(${ARGS_NAME}_ROOT_DIR ${${ARGS_NAME}_ROOT_DIR_TMP} CACHE PATH ${${ARGS_NAME}_ROOT_DIR_DESCR} FORCE)
    endif()

    set(REQUIRED_VARS ${ARGS_NAME}_INCLUDE_DIR)

    if("${ARGS_LIBNAME}" STREQUAL "")
        set(ARGS_LIBNAME ${ARGS_NAME})
    endif()

    if("${ARGS_RUNTIMENAME}" STREQUAL "")
        set(ARGS_RUNTIMENAME ${ARGS_LIBNAME})
    endif()

    if("${ARGS_DLIBNAME}" STREQUAL "")
        set(ARGS_DLIBNAME ${ARGS_LIBNAME}d)
    endif()

    if("${ARGS_DARGS_DRUNTIMENAME}" STREQUAL "")
        set(ARGS_DRUNTIMENAME ${ARGS_DLIBNAME})
    endif()

    if(NOT ARGS_HEADERONLY)
        find(${ARGS_NAME}_LIBRARY STATUS
            PATHS ${${ARGS_NAME}_SEARCH_DIRS}
            INDICATOR ${ARGS_LIBNAME}${CMAKE_LINK_LIBRARY_SUFFIX}
            DOC "${ARGS_NAME} libraries")
        find(${ARGS_NAME}_DEBUG_LIBRARY STATUS
            PATHS ${${ARGS_NAME}_SEARCH_DIRS}
            INDICATOR ${ARGS_DLIBNAME}${CMAKE_LINK_LIBRARY_SUFFIX}
            DOC "${ARGS_NAME} debug libraries")

        list(APPEND REQUIRED_VARS ${ARGS_NAME}_LIBRARY)

        if(NOT ARGS_STATIC)
        find(${ARGS_NAME}_RUNTIME STATUS
            PATHS ${${ARGS_NAME}_SEARCH_DIRS}
            INDICATOR ${ARGS_RUNTIMENAME}${CMAKE_SHARED_LIBRARY_SUFFIX}
            DOC "${ARGS_NAME} binaries")
        find(${ARGS_NAME}_DEBUG_RUNTIME STATUS
            PATHS ${${ARGS_NAME}_SEARCH_DIRS}
            INDICATOR ${ARGS_DRUNTIMENAME}${CMAKE_SHARED_LIBRARY_SUFFIX}
            DOC "${ARGS_NAME} debug binaries")
        endif()
    endif()

    find_package_handle_standard_args(${ARGS_NAME}
        FOUND_VAR ${ARGS_NAME}_FOUND
        REQUIRED_VARS ${REQUIRED_VARS})

    mark_as_advanced(${REQUIRED_VARS} ${ARGS_NAME}_DEBUG_LIB ${ARGS_NAME}_DEBUG_RUNTIME ${ARGS_NAME}_ROOT_DIR)

    if(${ARGS_NAME}_FOUND AND NOT TARGET ${ARGS_NAME}::${ARGS_NAME})
        create_target(${ARGS_NAME})
    endif()
endfunction(find_dependency)
