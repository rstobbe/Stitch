function cFourierTransformShiftSingleGpu

% CUDA Path
CUDApath = getenv('CUDA_PATH');      
CUDApath = [CUDApath,'\lib\x64'];

% CUDA Lib Path
CUDAlib = 'D:\Cuda\zz Library';

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart', ... 
    ['-L',CUDAlib], ...
    '-lCUDA61_FourierTransformShift_v11a', ...
    '-output','FourierTransformShiftSingleGpu61', ...
    'FourierTransformShiftSingleGpu.cpp');

