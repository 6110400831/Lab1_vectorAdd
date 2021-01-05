#include<stdio.h>

__global__ void parallel_vector_add(int* d_a, int* d_b, int* d_c, int* d_n)
{
	int i = (blockIdx.x*blockDim.x)+threadIdx.x;
	if(i < *d_n){
		printf("i am thread #%d and about to compute c[%d]\n", i, i);
		d_c[i] = d_a[i] + d_b[i];
	}
	else{
		printf("i am thread #%d I am doing nothing\n", i);
	}	
}

int main(){

	int n;

	scanf("%d",&n);

	//declare input and output on host
	int h_a[n];
	int h_b[n];

	for(int i = 0; i < n; i++){
		h_a[i] = i;
		h_b[i] = n-i;
	}

	int h_c[n];

	//part1 copy data from host to device
	int *d_a, *d_b, *d_c, *d_n;
	cudaMalloc((void **) &d_a, n*sizeof(int));
	cudaMalloc((void **) &d_b, n*sizeof(int));
	cudaMalloc((void **) &d_c, n*sizeof(int));
	cudaMalloc((void **) &d_n, sizeof(int));

	cudaMemcpy(d_a, &h_a, n*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, &h_b, n*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_n, &n, sizeof(int), cudaMemcpyHostToDevice);

	//part2 kernel launch
	cudaEvent_t start, stop;
	cudaEventCreate(&start);	
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	parallel_vector_add<<<(n+15)/16, 512>>>(d_a, d_b, d_c, d_n);
	cudaDeviceSynchronize();
	cudaEventRecord(stop);

	cudaEventSynchronize(stop);
	float millisec = 0;
	cudaEventElapsedTime(&millisec, start, stop);
	//part3 copy data from device back to host and free all data allocate on device
	cudaMemcpy(&h_c, d_c, n*sizeof(int), cudaMemcpyDeviceToHost);

	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);

	for(int i = 0; i < n; i++)
		printf("%d ", h_c[i]);
	printf("\n");
	printf("Effective time(ms): %f \n",millisec);
}
