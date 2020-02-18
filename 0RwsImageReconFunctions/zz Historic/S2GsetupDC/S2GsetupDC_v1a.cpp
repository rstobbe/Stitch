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
double *Kx,*Ky,*Kz,*Kern;
int CrtDatSz;
int *temp;

if (nrhs != 5) mexErrMsgTxt("Should have 5 inputs");
Kx = (double*)mxGetData(prhs[0]);     
Ky = (double*)mxGetData(prhs[1]);     
Kz = (double*)mxGetData(prhs[2]);     
Kern = (double*)mxGetData(prhs[3]);     
temp = (int*)mxGetData(prhs[4]); CrtDatSz = temp[0];

const mwSize *temp2;
int DatLen,KernSz;
temp2 = mxGetDimensions(prhs[1]);
DatLen = (int)temp2[1];
temp2 = mxGetDimensions(prhs[3]);
KernSz = (int)temp2[1];

//-------------------------------------
// Error Code Setup         
//-------------------------------------	
int errorlen = 200;
char *Error;
Error = (char*)mxCalloc(errorlen,sizeof(char));
strcpy(Error,"no error");

//-------------------------------------
// Determine #GPUs           
//-------------------------------------	
int *DevCnt;
DevCnt = (int*)mxCalloc(1,sizeof(int));
CUDAcount(DevCnt,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
mwSize GpuNum = *DevCnt;

//-------------------------------------
// Output                       
//-------------------------------------
mwSize *Handles;
mwSize Dim[2];
Dim[0] = 8; 
Dim[1] = GpuNum; 
plhs[0] = mxCreateNumericArray(2,Dim,mxUINT64_CLASS,mxREAL);
//plhs[0] = mxCreateNumericArray(2,Dim,mxINT64_CLASS,mxREAL);
Handles = (mwSize*)mxGetData(plhs[0]);
for (int n=0; n<Dim[0]*Dim[1]; n++){
    Handles[n] = 0;
}    
//--
mwSize *GpuNumPtr;
Dim[0] = 1; 
Dim[1] = 1;
plhs[1] = mxCreateNumericArray(2,Dim,mxUINT64_CLASS,mxREAL);
GpuNumPtr = (mwSize*)mxGetData(plhs[1]);
GpuNumPtr[0] = GpuNum;

//-------------------------------------
// Allocate Space on Host & Device                   
//-------------------------------------
mwSize *Tst;    // not used here
mwSize *HSampDatR,*HSampDatI,*HCrtDatC,*HCrtDatCTemp,*HKx,*HKy,*HKz,*HKern;
HSampDatR = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));
HSampDatI = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));
HCrtDatC = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));
HCrtDatCTemp = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));
HKx = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));
HKy = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));
HKz = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));
HKern = (mwSize*)mxCalloc(GpuNum,sizeof(mwSize));


ArrAllocDbl((int)GpuNum,HSampDatR,DatLen,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
ArrAllocDbl((int)GpuNum,HSampDatI,DatLen,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
Mat3DAllocDblC((int)GpuNum,HCrtDatC,CrtDatSz,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
// Mat3DInitDblC((int)GpuNum,HCrtDatC,CrtDatSz,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[2] = mxCreateString("CrtDatC"); return;
// 	}	
Mat3DAllocDblC((int)GpuNum,HCrtDatCTemp,CrtDatSz,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
// Mat3DInitDblC((int)GpuNum,HCrtDatCTemp,CrtDatSz,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[2] = mxCreateString("CrtDatCTemp"); return;
// 	}
ArrAllocDbl((int)GpuNum,HKx,DatLen,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
// ArrLoadDbl((int)GpuNum,Kx,HKx,DatLen,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[2] = mxCreateString("Kx"); return;
// 	}
ArrAllocDbl((int)GpuNum,HKy,DatLen,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
// ArrLoadDbl((int)GpuNum,Ky,HKy,DatLen,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[2] = mxCreateString("Ky"); return;
// 	}
ArrAllocDbl((int)GpuNum,HKz,DatLen,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
// ArrLoadDbl((int)GpuNum,Kz,HKz,DatLen,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[2] = mxCreateString("Kz"); return;
// 	}
Mat3DAllocDbl((int)GpuNum,HKern,KernSz,Tst,Error);
if (strcmp(Error,"no error") != 0) {
	plhs[2] = mxCreateString(Error); return;
	}
// Mat3DLoadDbl((int)GpuNum,Kern,HKern,KernSz,Error);
// if (strcmp(Error,"no error") != 0) {
// 	plhs[2] = mxCreateString("Kern"); return;
// 	}

//-------------------------------------
// Load / Initialize                    
//-------------------------------------

//-------------------------------------
// Return Handles                  
//-------------------------------------
// mwSize Test = (mwSize)mxCalloc(GpuNum,sizeof(mwSize));
// 
// Test =  HSampDatR[0];
// Handles[0] = Test;
// Test =  HSampDatI[0];
// Handles[1] = Test;
// Test =  HCrtDatC[0];
// Handles[2] = Test;
// Test =  HCrtDatCTemp[0];
// Handles[3] = Test;
// Test =  HKx[0];
// Handles[4] = Test;
// Test =  HKy[0];
// Handles[5] = Test;
// Test =  HKz[0];
// Handles[6] = Test;
// Test =  HKern[0];
// Handles[7] = Test;

Handles[0] = HSampDatR[0];
Handles[1] = HSampDatI[0];
Handles[2] = HCrtDatC[0];
Handles[3] = HCrtDatCTemp[0];
Handles[4] = HKx[0];
Handles[5] = HKy[0];
Handles[6] = HKz[0];
Handles[7] = HKern[0];

//-------------------------------------
// Return Error                    
//------------------------------------- 
plhs[2] = mxCreateString(Error);

}

