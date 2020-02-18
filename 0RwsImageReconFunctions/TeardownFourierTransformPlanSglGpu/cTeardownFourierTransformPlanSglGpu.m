function cTeardownFourierTransformPlanSglGpu

% CUDA Path
CUDApath = getenv('CUDA_PATH');      
CUDApath = [CUDApath,'\lib\x64'];

% CUDA Lib Path
CUDAlib = 'D:\Cuda\zz Library';

mex('-R2018a',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart','-lcufft', ... 
    ['-L',CUDAlib], ...
    '-lCUDA61_FourierTransform_v11a', ...
    '-output','TeardownFourierTransformPlanSglGpu61', ...
    'TeardownFourierTransformPlanSglGpu.cpp');

