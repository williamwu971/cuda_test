cmake_minimum_required(VERSION 3.22)
project(cuda_test CUDA)

set(CMAKE_CUDA_STANDARD 14)

add_executable(cuda_test main.cu matrix.cu)

set_target_properties(cuda_test PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
