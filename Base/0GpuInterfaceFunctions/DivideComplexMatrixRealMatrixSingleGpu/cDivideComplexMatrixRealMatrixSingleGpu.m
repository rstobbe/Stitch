function cDivideComplexMatrixRealMatrixSingleGpu

% CUDA Path
CUDApath = getenv('CUDA_PATH');      
CUDApath = [CUDApath,'\lib\x64'];

% CUDA Lib Path
CUDAlib = 'D:\Cuda\zz Library';

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart','-lcufft', ... 
    ['-L',CUDAlib], ...
    '-lCUDA61_DivideMatrixComplexReal_v11a', ...
    '-output','DivideComplexMatrixRealMatrixSingleGpu61', ...
    'DivideComplexMatrixRealMatrixSingleGpu.cpp');

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart','-lcufft', ... 
    ['-L',CUDAlib], ...
    '-lCUDA75_DivideMatrixComplexReal_v11a', ...
    '-output','DivideComplexMatrixRealMatrixSingleGpu75', ...
    'DivideComplexMatrixRealMatrixSingleGpu.cpp');

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart','-lcufft', ... 
    ['-L',CUDAlib], ...
    '-lCUDA86_DivideMatrixComplexReal_v11a', ...
    '-output','DivideComplexMatrixRealMatrixSingleGpu86', ...
    'DivideComplexMatrixRealMatrixSingleGpu.cpp');

