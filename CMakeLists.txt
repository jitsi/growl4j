cmake_minimum_required(VERSION 3.16)
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9" CACHE STRING "Minimum OS X deployment version")
project(growl4j OBJC)

set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_DISABLE_SOURCE_CHANGES  ON)

if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
    message(SEND_ERROR "In-source builds are not allowed.")
endif ()

set(CMAKE_PREFIX_PATH ${PROJECT_SOURCE_DIR}/Frameworks)
set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR}/src/main/resources)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake_modules")

find_package(JNI REQUIRED)
find_package(Growl REQUIRED)

add_library(${PROJECT_NAME} SHARED
            src/main/objc/org_growl4j_Growl.m
            )

target_include_directories(${PROJECT_NAME} PUBLIC
                           ${JNI_INCLUDE_DIRS}
                           ${GROWL_INCLUDE_DIR}
                           )

target_link_libraries(${PROJECT_NAME}
                      "-framework AppKit"
                      ${GROWL_LIBRARY}
                      )