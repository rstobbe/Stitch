function cS2GconvDC_v1a

% CUDA Path
CUDApath = getenv('CUDA_PATH');      
CUDApath = [CUDApath,'\lib\x64'];

% CUDA Lib Path
CUDAlib = 'D:\Compass\1 Scripts\zy NonMatlabSubRoutines\Set 1.5\CudaSubRoutines\zz Library';

mex('-largeArrayDims',...                                     
    ['-I',CUDAlib], ...
    ['-L',CUDApath],'-lcudart', ... 
    ['-L',CUDAlib], ...
    '-lCUDA_GeneralDM_v1c', ...
    'S2GconvDC_v1a.cpp');

 % -O = compile with opitmization         library to link with... (the "cudart" library is the CUDA runtime library)