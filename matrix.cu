#include <cstdio>
#include <cstdlib>
#include "asm.h"

#define BLOCK_SIZE 16


__global__ void gpu_matrix_mult(const int *a, const int *b, int *c, int m, int n, int k) {
    unsigned row = blockIdx.y * blockDim.y + threadIdx.y;
    unsigned col = blockIdx.x * blockDim.x + threadIdx.x;
    int sum = 0;
    if (col < k && row < m) {
        for (int i = 0; i < n; i++) {
            sum += a[row * n + i] * b[i * k + col];
        }
        c[row * k + col] = sum;
    }
}

void cpu_matrix_mult(const int *h_a, const int *h_b, int *h_result, int m, int n, int k) {

    omp_set_num_threads(10);
#pragma omp parallel for schedule(dynamic, 10)
    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < k; ++j) {
            int tmp = 0;
            for (int h = 0; h < n; ++h) {
                tmp += h_a[i * n + h] * h_b[h * k + j];
            }
            h_result[i * k + j] = tmp;
        }
    }
}


int main() {
    /* Fixed seed for illustration */
    srand(time(NULL));

    int m = 2000;
    int n = 2000;
    int k = 2000;

    // allocate memory in host RAM, h_cc is used to store CPU result
    int *h_a, *h_b, *h_c, *h_cc;
    cudaMallocHost((void **) &h_a, sizeof(int) * m * n);
    cudaMallocHost((void **) &h_b, sizeof(int) * n * k);
    cudaMallocHost((void **) &h_c, sizeof(int) * m * k);
    cudaMallocHost((void **) &h_cc, sizeof(int) * m * k);

    // random initialize matrix A
    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < n; ++j) {
            h_a[i * n + j] = rand() % 12;
        }
    }

    // random initialize matrix B
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < k; ++j) {
            h_b[i * k + j] = rand() % 12;
        }
    }

    declare_timer
    start_timer

    // Allocate memory space on the device
    int *d_a, *d_b, *d_c;
    cudaMalloc((void **) &d_a, sizeof(int) * m * n);
    cudaMalloc((void **) &d_b, sizeof(int) * n * k);
    cudaMalloc((void **) &d_c, sizeof(int) * m * k);

    // copy matrix A and B from host to device memory
    cudaMemcpy(d_a, h_a, sizeof(int) * m * n, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, sizeof(int) * n * k, cudaMemcpyHostToDevice);

    unsigned int grid_rows = (m + BLOCK_SIZE - 1) / BLOCK_SIZE;
    unsigned int grid_cols = (k + BLOCK_SIZE - 1) / BLOCK_SIZE;
    dim3 dimGrid(grid_cols, grid_rows);
    dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);

    // Launch kernel
    gpu_matrix_mult<<<dimGrid, dimBlock>>>(d_a, d_b, d_c, m, n, k);
    cudaMemcpy(h_c, d_c, sizeof(int) * m * k, cudaMemcpyDeviceToHost);

    stop_timer
    printf("GPU: %.2fs\n", (double) elapsed / 1000000.0f);

    start_timer
    cpu_matrix_mult(h_a, h_b, h_cc, m, n, k);
    stop_timer
    printf("CPU: %.2fs\n", (double) elapsed / 1000000.0f);


    // validate results computed by GPU
    int all_ok = 1;
    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < k; ++j) {
            if (h_cc[i * k + j] != h_c[i * k + j]) {
                all_ok = 0;
            }
        }
    }

    // roughly compute speedup
    if (!all_ok)printf("incorrect results\n");


    return 0;
}