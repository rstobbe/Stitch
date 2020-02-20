///==========================================================
/// (v1a)
///		
///==========================================================

#include "mex.h"
#include "matrix.h"
#include "math.h"
#include "string.h"
#include "CUDA_GeneralSgl1_v1f.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{

//-------------------------------------
// Input                        
//-------------------------------------
if (nrhs != 3) mexErrMsgTxt("Should have 3 inputs");
mwSize *GpuNum,*HKernel,*KernelMemDims;

GpuNum = mxGetUint64s(prhs[0]);
HKernel = mxGetUint64s(prhs[1]);
KernelMemDims = mxGetUint64s(prhs[2]);

//-------------------------------------
// Output                       
//-------------------------------------
if (nlhs != 2) mexErrMsgTxt("Should have 2 outputs");

mwSize ArrDim[3];
ArrDim[0] = KernelMemDims[0]; 
ArrDim[1] = KernelMemDims[1]; 
ArrDim[2] = KernelMemDims[2]; 
plhs[0] = mxCreateNumericArray(3,ArrDim,mxSINGLE_CLASS,mxREAL);
float *Kernel;
Kernel = (float*)mxGetSingles(plhs[0]);

char *Error;
mwSize errorlen = 200;
Error = (char*)mxCalloc(errorlen,sizeof(char));
strcpy(Error,"no error");

//-------------------------------------
// Return Memory                
//-------------------------------------
mwSize *ArrLen;
ArrLen = (mwSize*)mxCalloc(1,sizeof(mwSize));
ArrLen[0] = KernelMemDims[0]*KernelMemDims[1]*KernelMemDims[2];
ArrReturnSgl(GpuNum,Kernel,HKernel,ArrLen,Error);

//-------------------------------------
// Return Error                    
//------------------------------------- 
plhs[1] = mxCreateString(Error);
mxFree(Error);
mxFree(ArrLen);

}

