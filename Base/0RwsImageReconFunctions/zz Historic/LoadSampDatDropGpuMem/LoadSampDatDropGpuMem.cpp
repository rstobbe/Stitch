///==========================================================
/// (v1a)
///		
///==========================================================

#include "mex.h"
#include "matrix.h"
#include "math.h"
#include "string.h"
#include "CUDA_GeneralSgl_v1d.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{

//-------------------------------------
// Input                        
//-------------------------------------
if (nrhs != 7) mexErrMsgTxt("Should have 7 inputs");
mwSize *GpuNum,*HSampDat,*ProjStart,*SampDatMemDims,*Rcvrs,*Idx;
float *SampDat;
GpuNum = mxGetUint64s(prhs[0]);
SampDat = (float*)mxGetComplexSingles(prhs[1]);
HSampDat = mxGetUint64s(prhs[2]);
ProjStart = mxGetUint64s(prhs[3]);
SampDatMemDims = mxGetUint64s(prhs[4]);
Rcvrs = mxGetUint64s(prhs[5]);
Idx = mxGetUint64s(prhs[6]);

//-------------------------------------
// Output                       
//-------------------------------------
if (nlhs != 1) mexErrMsgTxt("Should have 1 outputs");

char *Error;
mwSize errorlen = 200;
Error = (char*)mxCalloc(errorlen,sizeof(char));
strcpy(Error,"no error");

//-------------------------------------
// Load GPU            
//-------------------------------------
const mwSize *SampDatDims;
SampDatDims = mxGetDimensions(prhs[1]);
const mwSize *RcvrNum;
RcvrNum = mxGetDimensions(prhs[5]);

mwSize *SelRcvr,*ProjInc;
SelRcvr = (mwSize*)mxCalloc(1,sizeof(mwSize));
ProjInc = (mwSize*)mxCalloc(1,sizeof(mwSize));

float *SampDatPtr;
for (int n=0; n<RcvrNum[0]; n++){	
    SelRcvr[0] = Rcvrs[n];
    for (int m=0; m<SampDatMemDims[1]; m++){
        ProjInc[0] = m;
        SampDatPtr = SampDat + 2*((SelRcvr[0]*SampDatDims[0])+((ProjStart[0]+ProjInc[0])*SampDatDims[0]*SampDatDims[1]));  // 2x for complex
        ArrLoadSglC(SelRcvr,SampDatPtr,HSampDat,SampDatMemDims,ProjInc,Error);
    }
}

//-------------------------------------
// Return Error                    
//------------------------------------- 
plhs[0] = mxCreateString(Error);
mxFree(Error);
mxFree(SelRcvr);

}

