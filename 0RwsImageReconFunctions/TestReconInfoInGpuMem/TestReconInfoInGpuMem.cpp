///==========================================================
/// (v1a)
///		
///==========================================================

#include "mex.h"
#include "matrix.h"
#include "math.h"
#include "string.h"
#include "CUDA_GeneralSgl_v11f.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{

//-------------------------------------
// Input                        
//-------------------------------------
if (nrhs != 3) mexErrMsgTxt("Should have 3 inputs");
mwSize *GpuNum,*HReconInfo,*ReconInfoMemDims;

GpuNum = mxGetUint64s(prhs[0]);
HReconInfo = mxGetUint64s(prhs[1]);
ReconInfoMemDims = mxGetUint64s(prhs[2]);

//-------------------------------------
// Output                       
//-------------------------------------
if (nlhs != 2) mexErrMsgTxt("Should have 2 outputs");

mwSize ArrDim[3];
ArrDim[0] = ReconInfoMemDims[0]; 
ArrDim[1] = ReconInfoMemDims[1]; 
ArrDim[2] = ReconInfoMemDims[2]; 
plhs[0] = mxCreateNumericArray(3,ArrDim,mxSINGLE_CLASS,mxREAL);
float *ReconInfo;
ReconInfo = (float*)mxGetSingles(plhs[0]);

char *Error;
mwSize errorlen = 200;
Error = (char*)mxCalloc(errorlen,sizeof(char));
strcpy(Error,"no error");

//-------------------------------------
// Return Memory                
//-------------------------------------
mwSize *ArrLen;
ArrLen = (mwSize*)mxCalloc(1,sizeof(mwSize));
ArrLen[0] = ReconInfoMemDims[0]*ReconInfoMemDims[1]*ReconInfoMemDims[2];
ArrReturnSglOne(GpuNum,ReconInfo,HReconInfo,ArrLen,Error);

//-------------------------------------
// Return Error                    
//------------------------------------- 
plhs[1] = mxCreateString(Error);
mxFree(Error);
mxFree(ArrLen);

}

