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
double *Kx;
mwSize* HKx;

if (nrhs != 2) mexErrMsgTxt("Should have 2 inputs");
HKx = (mwSize*)mxGetData(prhs[0]);     
Kx = (double*)mxGetData(prhs[1]);  

const mwSize *temp2;
int DatLen;
temp2 = mxGetDimensions(prhs[0]);
DatLen = (int)temp2[1];

//-------------------------------------
// Error Code Setup         
//-------------------------------------	
int errorlen = 200;
char *Error;
Error = (char*)mxCalloc(errorlen,sizeof(char));
strcpy(Error,"no error");

//-------------------------------------
// Load                
//-------------------------------------
ArrLoadDbl(1,Kx,HKx,DatLen,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[0] = mxCreateString(Error); return;
	}
ArrLoadDbl(1,Kx,HKx,DatLen,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[0] = mxCreateString(Error); return;
	}
ArrLoadDbl(1,Kx,HKx,DatLen,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[0] = mxCreateString(Error); return;
	}
ArrLoadDbl(1,Kx,HKx,DatLen,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[0] = mxCreateString(Error); return;
	}

// ArrReturnDbl(1,Kx,HKx,DatLen,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[0] = mxCreateString(Error); return;
// 	}

//-------------------------------------
// Return Error                    
//------------------------------------- 
plhs[0] = mxCreateString(Error);

}

