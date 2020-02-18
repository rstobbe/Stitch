///==========================================================
/// (v1a)
///		
///==========================================================

#include "mex.h"
#include "matrix.h"
#include "math.h"
#include "string.h"
#include "CUDA_FourierTransform_v11a.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{

//-------------------------------------
// Input                        
//-------------------------------------
if (nrhs != 4) mexErrMsgTxt("Should have 4 inputs");
mwSize *GpuNum,*HImageMatrix,*HKspaceMatrix,*HFourierTransformPlan;
GpuNum = mxGetUint64s(prhs[0]);
HImageMatrix = mxGetUint64s(prhs[1]);
HKspaceMatrix = mxGetUint64s(prhs[2]);
HFourierTransformPlan = mxGetUint64s(prhs[3]);

//-------------------------------------
// Output                       
//-------------------------------------
if (nlhs != 1) mexErrMsgTxt("Should have 1 outputs");

char *Error;
mwSize errorlen = 200;
Error = (char*)mxCalloc(errorlen,sizeof(char));
strcpy(Error,"no error");

//-------------------------------------
// Fourier Transform              
//-------------------------------------
unsigned int *HTemp;
HTemp = (unsigned int*)mxCalloc(1,sizeof(unsigned int));
HTemp[0] = (unsigned int)HFourierTransformPlan[0];
IFFT3DSglGpu(GpuNum,HImageMatrix,HKspaceMatrix,HTemp,Error);

//-------------------------------------
// Return                  
//------------------------------------- 
plhs[0] = mxCreateString(Error);
mxFree(Error);

}

