# Image-Processing-with-CUDA
Parallel image processing (blur filter) using CUDA.  
Usage: ./pa5.x r (input filename).ppm (output filename).ppm

## Program Function:
The program transfers the input image to GPU memory and divides it efficiently among GPU cores. The rows and blocks are assigned to optimize the blur operation. The blurred image (based on radius r) is transfered back to host memory and an output ppm file is created.
