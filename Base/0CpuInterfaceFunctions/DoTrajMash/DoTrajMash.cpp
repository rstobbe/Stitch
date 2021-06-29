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
if (nrhs != 9) mexErrMsgTxt("Should have 9 inputs");
mwSize NumAve,TbStart,TbStop,TbSize,RbStart,RbStop,RbSize;
float *DataBlock;
float *Weights;
DataBlock = mxGetSingles(prhs[0]);
Weights = mxGetSingles(prhs[1]);
NumAve = (mwSize)mxGetScalar(prhs[2]);
TbStart = (mwSize)mxGetScalar(prhs[3]);
TbStop = (mwSize)mxGetScalar(prhs[4]);
TbSize = (mwSize)mxGetScalar(prhs[5]);
RbStart = (mwSize)mxGetScalar(prhs[6]);
RbStop = (mwSize)mxGetScalar(prhs[7]);
RbSize = (mwSize)mxGetScalar(prhs[8]);

const mwSize *temp;
mwSize NumCol,NumAcq,NumRx,NumTraj;
temp = mxGetDimensions(prhs[0]);
NumCol = (mwSize)temp[0];
NumAcq = (mwSize)temp[1];
NumRx = (mwSize)temp[2];
NumTraj = mwSize(float(NumAcq)/float(NumAve));

//-------------------------------------
// Output                       
//-------------------------------------
if (nlhs != 1) mexErrMsgTxt("Should have 1 output");

mwSize ArrDim[3];
ArrDim[0] = NumCol; 
ArrDim[1] = TbSize; 
ArrDim[2] = RbSize; 
plhs[0] = mxCreateNumericArray(3,ArrDim,mxSINGLE_CLASS,mxREAL);
float *WeightedDataBlock;
WeightedDataBlock = (float*)mxGetSingles(plhs[0]);

//-------------------------------------
// Weight / Sum Data         
//-------------------------------------
int n,m,p,i;
mwSize Traj,Acq,Rx;
int Rb2Do, Tb2Do;
Rb2Do = RbStop - RbStart + 1;
Tb2Do = TbStop - TbStart + 1;

for (m=0; m<Rb2Do; m++) { 
    for (n=0; n<Tb2Do; n++) { 
        for (p=0; p<NumCol; p++) {    
            for (i=0; i<NumAve; i++) {
                Traj = (TbStart-1) + n;
                Acq = Traj + i*NumTraj;
                Rx = (RbStart-1) + m;
                WeightedDataBlock[m*TbSize*NumCol + n*NumCol + p] += Weights[Traj*NumAve + i] * DataBlock[Rx*NumAcq*NumCol + Acq*NumCol + p];
                //WeightedDataBlock[m*TbSize*NumCol + n*NumCol + p] = float(Rx*NumAcq*NumCol + Acq*NumCol + p);
                //WeightedDataBlock[m*TbSize*NumCol + n*NumCol + p] += Weights[Traj*NumAve + i];
            }
        }
    }
}


}

