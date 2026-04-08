# Find or build LarsHagemann/bimap — a header-only bidirectional map.
# Provides the stde::bimap<K,V> template; creates interface target: bimap::bimap

message(STATUS "Configuring bimap dependency...")

find_package(bimap QUIET)

if(NOT bimap_FOUND)
    message(STATUS "bimap not found. Fetching via CPM...")

    CPMAddPackage(
        NAME bimap
        GITHUB_REPOSITORY LarsHagemann/bimap
        GIT_TAG master
    )

    if(bimap_ADDED)
        # Header-only: create an interface target pointing at the source dir
        add_library(bimap::bimap INTERFACE IMPORTED GLOBAL)
        target_include_directories(bimap::bimap INTERFACE "${bimap_SOURCE_DIR}")
        message(STATUS "bimap fetched and interface target created.")
    else()
        message(FATAL_ERROR "Failed to fetch bimap via CPM.")
    endif()
else()
    message(STATUS "Found system bimap: ${bimap_VERSION}")
endif()
