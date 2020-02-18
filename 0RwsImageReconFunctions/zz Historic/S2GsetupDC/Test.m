function Test

Kx = 1:1:100000000;
Ky = 1:1:100000000;
Kz = 1:1:100000000;
Kern = 1:1:10;
CrtDatSz = 50;
CrtDatSz = uint64(CrtDatSz);

[Handles,GpuNum,Tst,error] = S2GsetupDC_v1b(Kx,Ky,Kz,Kern,CrtDatSz);

test = 0;

