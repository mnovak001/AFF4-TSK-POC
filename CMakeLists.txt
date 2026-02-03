cmake_minimum_required(VERSION 3.13)
project(aff4tsk LANGUAGES C)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(Threads REQUIRED)

include_directories(/usr/local/include)
link_directories(/usr/local/lib)

# --------------------
# Shared library
# --------------------
add_library(aff4tsk SHARED
  aff4_tsk_img.c
  aff4_c_api.c
)

target_link_libraries(aff4tsk
  tsk
  aff4
  Threads::Threads
)

# --------------------
# Test executable
# --------------------
add_executable(test_aff4tsk
  test.c
)

# Link test against the library we just built
target_link_libraries(test_aff4tsk
  aff4tsk
  tsk
  aff4
  Threads::Threads
)
