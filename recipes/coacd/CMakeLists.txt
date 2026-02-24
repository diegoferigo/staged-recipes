cmake_minimum_required(VERSION 3.24)
project(CoACD VERSION 1.0.7 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

if(UNIX)
    list(APPEND CMAKE_MODULE_PATH "$ENV{PREFIX}/lib/cmake/OpenVDB")
elseif(WIN32)
    file(TO_CMAKE_PATH "$ENV{PREFIX}" CONDA_PREFIX_FWD)
    list(APPEND CMAKE_MODULE_PATH "${CONDA_PREFIX_FWD}/Library/lib/cmake/OpenVDB")
    # Add /bigobj to MSVC to avoid C1128 error.
    add_compile_options(/bigobj)
endif()
message(STATUS "CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")

find_package(spdlog REQUIRED)
find_package(OpenVDB REQUIRED)
find_package(OpenMP REQUIRED)
find_package(Threads REQUIRED)

# ============
# Main library
# ============

file(GLOB_RECURSE COACD_SRC "src/*.cpp")
add_library(coacd SHARED ${COACD_SRC})
target_compile_definitions(coacd PRIVATE WITH_3RD_PARTY_LIBS=1)
target_include_directories(coacd PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/public>
    $<INSTALL_INTERFACE:include/coacd>
)
target_include_directories(coacd PRIVATE 3rd/cdt/CDT)
target_link_libraries(
    coacd
    PRIVATE
    spdlog::spdlog
    Threads::Threads
    OpenVDB::openvdb
    OpenMP::OpenMP_CXX
)

# =============
# C-API wrapper
# =============

add_library(coacd_c_api SHARED "public/coacd.cpp")
target_link_libraries(
    coacd_c_api
    PRIVATE
    coacd
    spdlog::spdlog
    OpenVDB::openvdb
)

# ==========
# Executable
# ==========

# Currently unused (could be used in tests).
add_executable(main main.cpp)
# set_target_properties(main PROPERTIES OUTPUT_NAME coacd)
target_link_libraries(
    main
    PRIVATE
    coacd
    spdlog::spdlog
    OpenVDB::openvdb
)

# ==========================
# Install and export targets
# ==========================

include(GNUInstallDirs)

install(
    TARGETS coacd coacd_c_api
    EXPORT coacdTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(
    FILES "public/coacd.h"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/coacd
)

install(
    EXPORT coacdTargets
    FILE coacdTargets.cmake
    NAMESPACE CoACD::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/coacd
)

include(CMakePackageConfigHelpers)

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/coacdConfig.cmake.in
"@PACKAGE_INIT@
include(\"\${CMAKE_CURRENT_LIST_DIR}/coacdTargets.cmake\")
")

configure_package_config_file(
    ${CMAKE_CURRENT_BINARY_DIR}/coacdConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/coacdConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/coacd
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/coacdConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/coacdConfig.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/coacdConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/coacd
)
