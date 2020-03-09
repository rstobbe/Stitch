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
if (nrhs != 2) mexErrMsgTxt("Should have 2 inputs");
mwSize *Dim1,*Dim2;
Dim1 = mxGetUint64s(prhs[0]);
Dim2 = mxGetUint64s(prhs[1]);

//-------------------------------------
// Output                       
//-------------------------------------
if (nlhs != 1) mexErrMsgTxt("Should have 1 outputs");
mwSize MatrixDims[2];
MatrixDims[0] = Dim1[0]; 
MatrixDims[1] = Dim2[0]; 
plhs[0] = mxCreateNumericArray(2,MatrixDims,mxSINGLE_CLASS,mxCOMPLEX);

}

