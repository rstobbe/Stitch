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
mwSize *HSampDatR,*HSampDatI;

if (nrhs != 2) mexErrMsgTxt("Should have 2 inputs");
HSampDatR = (mwSize*)mxGetData(prhs[0]);     
HSampDatI = (mwSize*)mxGetData(prhs[1]);   

const mwSize *temp2;
int DatLen;
temp2 = mxGetDimensions(prhs[0]);
DatLen = (int)temp2[1];

DatLen = 200;

//-------------------------------------
// Output                       
//-------------------------------------
double *SampDatR,*SampDatI;
mwSize Dat_Dim[2];
if (nlhs != 2) mexErrMsgTxt("Should have 2 outputs");
Dat_Dim[0] = DatLen; 
Dat_Dim[1] = 1; 
plhs[0] = mxCreateNumericArray(2,Dat_Dim,mxDOUBLE_CLASS,mxCOMPLEX);
SampDatR = (double*)mxGetPr(plhs[0]); 
SampDatI = (double*)mxGetPi(plhs[0]); 
SampDatI[0] = HSampDatI[0];

//-------------------------------------
// Error Code Setup         
//-------------------------------------	
int errorlen = 200;
char *Error;
Error = (char*)mxCalloc(errorlen,sizeof(char));
strcpy(Error,"no error");

//-------------------------------------
// Return Data                    
//-------------------------------------
// ArrReturnDbl(1,SampDatR,HSampDatR,DatLen,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[1] = mxCreateString(Error); return;
// 	}
ArrReturnDbl(1,SampDatI,HSampDatI,DatLen,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[1] = mxCreateString(Error); return;
	}

//-------------------------------------
// Return Error                    
//------------------------------------- 
strcpy(Error,"end");
plhs[1] = mxCreateString(Error);

}

