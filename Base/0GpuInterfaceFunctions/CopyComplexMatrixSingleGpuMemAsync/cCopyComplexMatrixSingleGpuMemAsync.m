function cCopyComplexMatrixSingleGpuMemAsync

% CUDA Path
CUDApath = getenv('CUDA_PATH');      
CUDApath = [CUDApath,'\lib\x64'];

% CUDA Lib Path
CUDAlib = 'D:\Cuda\zz Library';

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart','-lcufft', ... 
    ['-L',CUDAlib], ...
    '-lCUDA61_GeneralSgl_v11f', ...
    '-output','CopyComplexMatrixSingleGpuMemAsync61', ...
    'CopyComplexMatrixSingleGpuMemAsync.cpp');

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart','-lcufft', ... 
    ['-L',CUDAlib], ...
    '-lCUDA75_GeneralSgl_v11f', ...
    '-output','CopyComplexMatrixSingleGpuMemAsync75', ...
    'CopyComplexMatrixSingleGpuMemAsync.cpp');

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart','-lcufft', ... 
    ['-L',CUDAlib], ...
    '-lCUDA86_GeneralSgl_v11f', ...
    '-output','CopyComplexMatrixSingleGpuMemAsync86', ...
    'CopyComplexMatrixSingleGpuMemAsync.cpp');
