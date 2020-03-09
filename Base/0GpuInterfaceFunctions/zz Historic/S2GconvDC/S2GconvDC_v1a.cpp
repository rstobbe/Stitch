///==========================================================
/// (v1a)
///		
///==========================================================

#include "mex.h"
#include "matrix.h"
#include "math.h"
#include "string.h"
#include "CUDA_GeneralDM_v1c.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{

//-------------------------------------
// Input                        
//-------------------------------------
double *SampDatR,*SampDatI;
int *temp;
int GpuNum;

if (nrhs != 3) mexErrMsgTxt("Should have 3 inputs");
SampDatR = mxGetPr(prhs[0]);
SampDatI = mxGetPi(prhs[0]);
temp = (int*)mxGetData(prhs[1]); GpuNum = temp[0];
// status = prhs[2];

const mwSize *temp2;
int DatLen;
temp2 = mxGetDimensions(prhs[0]);
DatLen = (int)temp2[0];

//-------------------------------------
// Display                  
//-------------------------------------	
sprintf(Status,"CUDA Memory Load: %i GPUs",GpuNum);
mxSetProperty(prhs[2],0,"String",mxCreateString(Status));
mexEvalString("drawnow");
	
//-------------------------------------
// Load                  
//-------------------------------------
ArrLoadDbl((int)GpuNum,SampDatR,HSampDatR,DatLen,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[0] = mxCreateString(Error); return;
	}
ArrLoadDbl((int)GpuNum,SampDatI,HSampDatI,DatLen,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[0] = mxCreateString(Error); return;
	}
	
//-------------------------------------
// Return Error                    
//------------------------------------- 
plhs[0] = mxCreateString(Error);

}

