function cAllocateSampDatGpuMem

% CUDA Path
CUDApath = getenv('CUDA_PATH');      
CUDApath = [CUDApath,'\lib\x64'];

% CUDA Lib Path
CUDAlib = 'D:\Cuda\zz Library';

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart', ... 
    ['-L',CUDAlib], ...
    '-lCUDA61_GeneralSgl_v11f', ...
    '-output','AllocateSampDatGpuMem61', ...
    'AllocateSampDatGpuMem.cpp');

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart', ... 
    ['-L',CUDAlib], ...
    '-lCUDA75_GeneralSgl_v11f', ...
    '-output','AllocateSampDatGpuMem75', ...
    'AllocateSampDatGpuMem.cpp');
