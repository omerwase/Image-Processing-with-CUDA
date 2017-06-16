# Makefile for PA5
all:
	gcc -c -o ppmFile.o ppmFile.c
	nvcc --device-c -arch=sm_20 -o pa5.o pa5.cu
	nvcc -arch=sm_20 -o pa5.x ppmFile.o pa5.o

clean:
	rm -f pa5.x pa5.o ppmFile.o