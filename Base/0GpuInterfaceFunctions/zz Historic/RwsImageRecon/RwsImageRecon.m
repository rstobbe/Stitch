%================================================================
%  
%================================================================

classdef RwsImageRecon < handle

    properties (SetAccess = private)                    
        NumGpuUsed;        
        SampDat; SampDatMemDims;
        HSampDat;
        HReconInfo; ReconInfoMemDims;
        HKernel; iKern; KernHw; KernelMemDims;
        HImageMatrix; ImageMatrixMemDims;
        HInvFilt; InvFiltMemDims;
        ProjStart;
    end
    methods 

%==================================================================
% Init
%==================================================================   
        function RECON = RwsImageRecon(NumGpuUsed)
            RECON.NumGpuUsed = uint64(NumGpuUsed);
        end

%==================================================================
% LoadReconInfoGpuMem
%   - kMat units -> (1/m)
%   - Array: 4(x,y,z,sdc) x read x proj
%   - suggested to clear 'ReconInfo' above - not needed in RAM
%================================================================== 
        function LoadReconInfoGpuMem(RECON,ReconInfo)
            if ~isa(ReconInfo,'single')
                error('ReconInfo must be in single format');
            end       
            sz = size(ReconInfo);
            if sz(1) ~= 4
                error('ReconInfo dimensionality problem');  
            end
            RECON.ReconInfoMemDims = uint64(sz);
            [RECON.HReconInfo,Error] = LoadReconInfoGpuMem(RECON.NumGpuUsed,ReconInfo);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end   
        
%==================================================================
% LoadKernelGpuMem
%   - suggested to clear 'Kernel' above - not needed in RAM
%================================================================== 
        function LoadKernelGpuMem(RECON,Kernel,iKern,KernHw)
            if ~isa(Kernel,'single')
                error('Kernel must be in single format');
            end 
            RECON.iKern = uint64(iKern);
            RECON.KernHw = uint64(KernHw);
            sz = size(Kernel);
            RECON.KernelMemDims = uint64(sz);
            [RECON.HKernel,Error] = LoadKernelGpuMem(RECON.NumGpuUsed,Kernel);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end    
        
%==================================================================
% LoadInvFiltGpuMem
%   - suggested to clear 'InvFilt' above - not needed in RAM
%================================================================== 
        function LoadInverseFiltGpuMem(RECON,InvFilt)
            if ~isa(InvFilt,'single')
                error('Kernel must be in single format');
            end  
            sz = size(InvFilt);
            RECON.InvFiltMemDims = uint64(sz);
            [RECON.HInvFilt,Error] = LoadInvFiltGpuMem(RECON.NumGpuUsed,InvFilt);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% AllocateImageMatrixGpuMem
%   - inpute = array of 3 dimension sizes
%==================================================================                      
        function AllocateImageMatrixGpuMem(RECON,ImageMatrixMemDims)
            RECON.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            [RECON.HImageMatrix,Error] = AllocateImageMatrixGpuMem(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          
        
%==================================================================
% AssignSampDatHandle
%   - This is not a memory copy -> just a RAM handle copy
%   - If SampDat altered outside a copy will be created -> don't do
%   - Recommended to 'clear' SampDat in calling function
%   - Format (read,rcvrs,proj,sets)
%   - If only 1 receiver, only use 1 GPU
%==================================================================                      
        function AssignSampDatHandle(RECON,SampDat)
            if ~isa(SampDat,'single')
                error('Data must be in single format');
            end
            sz = size(SampDat);
            if sz(2) == 1
                RECON.NumGpuUsed = uint64(1);
            end
            if isreal(SampDat)
                error('Data must complex');
            end
            RECON.SampDat = SampDat;
        end

%==================================================================
% AllocateSampDatGpuMem
%   'NumProjChunk' 
%       -> Not necessarily all trajectories
%       -> Option for testing realtime (1 traj vs. several bundled etc)
%==================================================================                      
        function AllocateSampDatGpuMem(RECON,NumProjChunk)
            sz = size(RECON.SampDat);
            if sz(1) == 0
                error('Assign ''SampDat'' handle first');    
            end
            RECON.SampDatMemDims(1) = sz(1);
            RECON.SampDatMemDims(2) = NumProjChunk;
            RECON.SampDatMemDims = uint64(RECON.SampDatMemDims);
            [RECON.HSampDat,Error] = AllocateSampDatGpuMem(RECON.NumGpuUsed,RECON.SampDatMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        
        
%==================================================================
% LoadSampDatGpuMem
%   -> Dims (read,proj,rcvr,reps)
%================================================================== 
        function LoadSampDatGpuMem(RECON,ProjStart,Rcvrs,Idx)
            sz = size(Rcvrs);
            if sz(2) ~= 1
                error('Rcvr array = Rcvrs x 1');    
            end
            sz = size(RECON.SampDat);
            if sz(1) ~= RECON.SampDatMemDims(1)
                error('Allocated GPU space SampDat readout do not match');
            end
            if ProjStart + RECON.SampDatMemDims(2) > sz(3)
                error('Specified ''ProjStart'' yeilds data loading beyond total number of projections');
            end
            if length(Rcvrs) ~= RECON.NumGpuUsed
                error('Number of receivers must equal number of GPUs');
            end
            for n = 1:RECON.NumGpuUsed
                if Rcvrs(n) > sz(2)-1
                    error('Specified receiver beyond data size');
                end
            end
            RECON.ProjStart = uint64(ProjStart);
            Rcvrs = uint64(Rcvrs);
            Idx = uint64(Idx);
            Error = LoadSampDatGpuMem(RECON.NumGpuUsed,RECON.SampDat,RECON.HSampDat,RECON.ProjStart,RECON.SampDatMemDims,Rcvrs,Idx);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 

%==================================================================
% GridSampDat
%==================================================================                      
        function GridSampDat(RECON)
            [Error] = GridSampDat(RECON.NumGpuUsed,RECON.HSampDat,RECON.HReconInfo,RECON.HKernel,RECON.HImageMatrix,...
                                    RECON.ProjStart,RECON.SampDatMemDims,RECON.ReconInfoMemDims,RECON.KernelMemDims,RECON.ImageMatrixMemDims,RECON.iKern,RECON.KernHw);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end           

%==================================================================
% FourierTransform
%==================================================================                      
        function FourierTransform(RECON)
            [Error] = GridSampDat(RECON.NumGpuUsed,RECON.HSampDat);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% ReturnImageMatrixGpuMem
%================================================================== 
        function ImageMatrix = ReturnImageMatrixGpuMem(RECON,TestGpuNum)
            if TestGpuNum > RECON.NumGpuUsed-1
                error('Specified ''TestGpuNum'' beyond number of GPUs used');
            end
            TestGpuNum = uint64(TestGpuNum);
            [ImageMatrix,Error] = ReturnImageMatrixGpuMem(TestGpuNum,RECON.HImageMatrix,RECON.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end           
        
%==================================================================
% TestSampDatInGpuMem
%   - Remember first GPU = 0
%================================================================== 
        function SampDat = TestSampDatInGpuMem(RECON,TestGpuNum)
            if TestGpuNum > RECON.NumGpuUsed-1
                error('Specified ''TestGpuNum'' beyond number of GPUs used');
            end
            TestGpuNum = uint64(TestGpuNum);
            [SampDat,Error] = TestSampDatInGpuMem(TestGpuNum,RECON.HSampDat,RECON.SampDatMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
 
%==================================================================
% TestReconInfoInGpuMem
%   - Remember first GPU = 0
%================================================================== 
        function ReconInfo = TestReconInfoInGpuMem(RECON,TestGpuNum)
            if TestGpuNum > RECON.NumGpuUsed-1
                error('Specified ''TestGpuNum'' beyond number of GPUs used');
            end
            TestGpuNum = uint64(TestGpuNum);
            [ReconInfo,Error] = TestReconInfoInGpuMem(TestGpuNum,RECON.HReconInfo,RECON.ReconInfoMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% TestKernelInGpuMem
%   - Remember first GPU = 0
%================================================================== 
        function Kernel = TestKernelInGpuMem(RECON,TestGpuNum)
            if TestGpuNum > RECON.NumGpuUsed-1
                error('Specified ''TestGpuNum'' beyond number of GPUs used');
            end
            TestGpuNum = uint64(TestGpuNum);
            [Kernel,Error] = TestKernelInGpuMem(TestGpuNum,RECON.HKernel,RECON.KernelMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
    end
end
        