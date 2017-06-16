/*
 * Programming Assignment 5 for CS 6F03 Winter 2017 Term
 * Filename: pa4.c
 * By: Omer Waseem (#000470449) and Erica Cheyne  (#001201341)
 * Description:
 * 	- Image blurred based on given radius using CUDA
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
extern "C" {
#include "ppmFile.h"
}

// kernel function that blurs entire image based on block/thread vector IDs
__global__ void blur(int *d_w, int *d_h, int *d_r, unsigned char *d_input, unsigned char *d_output) {
    int i, j, x, y, chan, temp, num, offset;
    i = blockIdx.x * blockDim.x + threadIdx.x;
    j = blockIdx.y * blockDim.y + threadIdx.y;
	for (chan = 0; chan < 3; chan++) {
		temp = 0;
		num = 0;
		for (y = j - (*d_r); y <= j + (*d_r); y++) {
	
			for (x = i - (*d_r); x <= i + (*d_r); x++) {
				if (x >= 0 && x < *d_w && y >= 0 && y < *d_h) {
					offset = (y * (*d_w) + x) * 3 + chan;
					temp += d_input[offset];
					num++;
				}
			}
		}
		temp /= num;
		offset = (j * (*d_w) + i) * 3 + chan;
		d_output[offset] = temp;
	}
}

int main (int argc, char *argv[]) {
    int w, h, r, temp;
    Image *inImage;
    Image *outImage;
    unsigned char *data;
    double time;
    clock_t begin, end;
	unsigned char *d_input;
    unsigned char *d_output;
    int *d_w, *d_h, *d_r;
    
    
    // check for correct number of input arguments
    if (argc != 4) {
		printf("Incorrect input arguments. Should be: <r> <input>.ppm <output>.ppm\n");
        return 0;
    }
    
	
	r = atoi(argv[1]);
	inImage = ImageRead(argv[2]);
	w = inImage->width;
	h = inImage->height;
	data = inImage->data;
	printf("Using image: %s, width: %d, height: %d, blur radius: %d\n",argv[2],w,h,r);
    printf("Waiting for GPU ...\n");

    // Grids are based on image size with blocks of 32x32
    dim3 blockD(32, 32);
    dim3 gridD((w + blockD.x - 1) / blockD.x, (h + blockD.y - 1) / blockD.y);
    
    // allocate GPU memory
    cudaMalloc((void**)&d_input, sizeof(unsigned char*) * w * h * 3);
    cudaMalloc((void**)&d_output, sizeof(unsigned char*) * w * h * 3);
    cudaMalloc((void**)&d_w, sizeof(int*));
    cudaMalloc((void**)&d_h, sizeof(int*));
    cudaMalloc((void**)&d_r, sizeof(int*));
    
    // copy values to GPU
    cudaMemcpy(d_input, data, w * h * 3, cudaMemcpyHostToDevice);
    cudaMemcpy(d_w, &w, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_h, &h, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_r, &r, sizeof(int), cudaMemcpyHostToDevice);
    
	printf("Blurring image ...\n");
    printf("Grid size: %d x %d\n", gridD.x, gridD.y);
	printf("Block size: %d x %d\n", blockD.x, blockD.y);
    printf("Total number of threads: %d\n", gridD.x * gridD.y * blockD.x * blockD.y);
    
    // begin blurring time
    begin = clock();
    
    // blur image using CUDA (except top and bottom edge)
    blur<<<gridD, blockD>>>(d_w, d_h, d_r, d_input, d_output);

	// create new image for output
	outImage = ImageCreate(w, h);
	ImageClear(outImage, 255, 255, 255);
	
	cudaThreadSynchronize();
    cudaDeviceSynchronize();
    
    // end blurring time
    end = clock();
    
	// copy blurred output from GPU to host
	printf("Blurring complete, assembling image ...\n");
    
    temp = w * h * 3;
    cudaMemcpy(outImage->data, d_output, temp, cudaMemcpyDeviceToHost);
	
	// write blurred image
	ImageWrite(outImage, argv[3]);
	printf("Blurred image created: %s\n", argv[3]);
    
    time = (double)(end-begin) / CLOCKS_PER_SEC;
    printf("Blurring execution time: %e s\n", time);
    
	free(inImage->data);
	free(outImage->data);
    cudaFree(d_input);
    cudaFree(d_output);
    cudaFree(d_w);
    cudaFree(d_h);
    cudaFree(d_r);
    
    return 0;
}
