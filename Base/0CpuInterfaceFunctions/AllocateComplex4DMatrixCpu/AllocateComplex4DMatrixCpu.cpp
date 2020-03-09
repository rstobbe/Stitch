///==========================================================
/// (v1a)
///		
///==========================================================

#include "mex.h"
#include "matrix.h"
#include "math.h"
#include "string.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{

//-------------------------------------
// Input                        
//-------------------------------------
if (nrhs != 4) mexErrMsgTxt("Should have 4 inputs");
mwSize *Dim1,*Dim2,*Dim3,*Dim4;
Dim1 = mxGetUint64s(prhs[0]);
Dim2 = mxGetUint64s(prhs[1]);
Dim3 = mxGetUint64s(prhs[2]);
Dim4 = mxGetUint64s(prhs[3]);

//-------------------------------------
// Output                       
//-------------------------------------
if (nlhs != 1) mexErrMsgTxt("Should have 1 outputs");
mwSize MatrixDims[4];
MatrixDims[0] = Dim1[0]; 
MatrixDims[1] = Dim2[0]; 
MatrixDims[2] = Dim3[0]; 
MatrixDims[3] = Dim4[0]; 
plhs[0] = mxCreateNumericArray(4,MatrixDims,mxSINGLE_CLASS,mxCOMPLEX);

}

