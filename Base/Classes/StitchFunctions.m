%================================================================
%  
%================================================================

classdef StitchFunctions < Grid & ReturnFov

    properties (SetAccess = private)
        Image;
        ImageArray;
        ImageHighSoS; ImageHighSoSArr;
        ImageLowSoS; ImageLowSoSArr;
        SuperFilt;
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchFunctions()
            obj@Grid;
            obj@ReturnFov;
        end
        
%==================================================================
% StitchInit
%==================================================================   
        function StitchInit(obj,log)
            obj.StitchFreeGpuMemory;
            obj.GpuInit;
            obj.GridKernelLoad(log);
            obj.InvFiltLoad(log);
            obj.FftInitialize(log);
            if strcmp(obj.StitchMetaData.CoilCombine,'Super')
                obj.SuperSetup(log);
            end
            obj.InitializeReconGpuBatching(log);
            obj.GridInitialize(log);
            if strcmp(obj.StitchMetaData.CoilCombine,'ReturnAll')
                obj.ReturnAllSetup(log);
            end
        end            
        
%==================================================================
% StitchGridDataBlock
%================================================================== 
        function StitchGridDataBlock(obj,DataObj,Info,log)           
            if obj.StitchMetaData.LoadTrajectoryLocal == 1
                Start = Info.TrajAcqStart;
                Stop = Info.TrajAcqStop;
                if Stop-Start+1 == DataObj.DataBlockLength
                    obj.GpuGrid(obj.ReconInfoMat(:,Start:Stop,:),DataObj.DataBlock,log);
                elseif Stop-Start+1 < DataObj.DataBlockLength
                    TempReconInfoMat = zeros(DataObj.NumCol,DataObj.DataBlockLength,4,'single');
                    TempReconInfoMat(:,1:Stop-Start+1,:) = obj.ReconInfoMat(:,Start:Stop,:);
                    obj.GpuGrid(TempReconInfoMat,DataObj.DataBlock,log);
                end
            else
                obj.GpuGrid(DataObj.ReconInfoMat,DataObj.DataBlock,log);
            end
        end

%==================================================================
% StitchFft
%================================================================== 
        function StitchFft(obj,log)           
            %log.info('Fourier Transform');
            Scale = 1e10;  % for Siemens (should come from above...)
            Scale = Scale/(obj.SubSamp^3);
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.KspaceScaleCorrect(GpuNum,GpuChan); 
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                    obj.InverseFourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);          
                    obj.MultInvFilt(GpuNum,GpuChan);
                    obj.ScaleImage(GpuNum,GpuChan,Scale); 
                end
            end
        end         
        
%==================================================================
% StitchFftCombine
%================================================================== 
        function StitchFftCombine(obj,log)           
            %log.info('Fourier Transform');
            Scale = 1e10;  % for Siemens (should come from above...)
            Scale = Scale/(obj.SubSamp^3);
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.KspaceScaleCorrect(GpuNum,GpuChan); 
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                    obj.InverseFourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);          
                    obj.MultInvFilt(GpuNum,GpuChan);
                    obj.ScaleImage(GpuNum,GpuChan,Scale); 
                end
            end
            %log.info('Combine/Return Images');
            if strcmp(obj.StitchMetaData.CoilCombine,'Super')
                obj.SuperInit(log);
                obj.SuperCombine(log);
            else
                obj.ReturnAllImages(log);
            end
        end                  

%==================================================================
% SuperSetup
%==================================================================   
        function SuperSetup(obj,log)
            %log.info('Allocate CPU Memory');
            obj.GetFinalMatrixDimensions;
            obj.Image = complex(zeros([obj.ImageReturnDims],'single'),0);
            obj.ImageHighSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);
            obj.ImageLowSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);        
            %log.info('Create/Load Super Filter');
            obj.CreateLoadSuperFilter(log);
            if not(isempty(obj.HSuperFilt))
                obj.FreeSuperFiltGpuMem;
            end
            obj.LoadSuperFiltGpuMem(obj.SuperFilt);
            obj.SuperInit(log);
        end   

%==================================================================
% SuperInit
%==================================================================   
        function SuperInit(obj,log)                      
            obj.ImageHighSoS = complex(zeros([obj.ImageMatrixMemDims],'single'),0);
            obj.ImageLowSoS = zeros([obj.ImageMatrixMemDims],'single');            
            if not(isempty(obj.HSuperLow))
                obj.FreeSuperMatricesGpuMem;
            end
            obj.AllocateSuperMatricesGpuMem;
        end
            
%==================================================================
% SuperCombine
%================================================================== 
        function SuperCombine(obj,log)
            %log.info('Super Combine');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);
                    obj.FourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);       % return to normal
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan); 
                    obj.SuperKspaceFilter(GpuNum,GpuChan);
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);         
                    obj.InverseFourierTransformSpecify(GpuNum,obj.HSuperLow,obj.HKspaceMatrix(GpuChan,:));    
                    obj.ImageFourierTransformShiftSpecify(GpuNum,obj.HSuperLow);          
                    obj.CreateLowImageConjugate(GpuNum);
                    obj.BuildLowSosImage(GpuNum);   
                    obj.BuildHighSosImage(GpuNum,GpuChan);           
                end
            end
            %log.info('Finish Super (Return HighSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperHighSoS);
            end
            %log.info('Finish Super (Return LowSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            %log.info('Finish Super (Combine Gpus)');
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,m));
            end
            %log.info('Finish Super (Create Image)');
            obj.Image = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            obj.Image = obj.ReturnFoV(obj.Image); 
        end        

%==================================================================
% SuperCombinePartial
%================================================================== 
        function SuperCombinePartial(obj,log)
            %log.info('Super Combine Partial');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);
                    obj.FourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);       % return to normal
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan); 
                    obj.SuperKspaceFilter(GpuNum,GpuChan);
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);         
                    obj.InverseFourierTransformSpecify(GpuNum,obj.HSuperLow,obj.HKspaceMatrix(GpuChan,:));    
                    obj.ImageFourierTransformShiftSpecify(GpuNum,obj.HSuperLow);          
                    obj.CreateLowImageConjugate(GpuNum);
                    obj.BuildLowSosImage(GpuNum);   
                    obj.BuildHighSosImage(GpuNum,GpuChan);           
                end
            end
        end         

%==================================================================
% SuperCombineFinish
%==================================================================         
        function SuperCombineFinish(obj,log)
            %log.info('Finish Super Partial (Return HighSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperHighSoS);
            end
            %log.info('Finish Super Partial (Return LowSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            %log.info('Finish Super Partial (Combine Gpus)');
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,m));
            end
            %log.info('Finish Super (Create Image)');
            obj.Image = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            obj.Image = obj.ReturnFoV(obj.Image); 
        end
                 
%==================================================================
% CreateLoadSuperFilter
%==================================================================         
        function CreateLoadSuperFilter(obj,log)
            fwidx = 2*round((obj.StitchMetaData.Fov/obj.StitchMetaData.Super.ProfRes)/2);
            fwidy = 2*round((obj.StitchMetaData.Fov/obj.StitchMetaData.Super.ProfRes)/2);
            fwidz = 2*round((obj.StitchMetaData.Fov/obj.StitchMetaData.Super.ProfRes)/2);
            F0 = Kaiser_v1b(fwidx,fwidy,fwidz,obj.StitchMetaData.Super.ProfFilt,'unsym');
            x = obj.ImageMatrixMemDims(1);
            y = obj.ImageMatrixMemDims(2);
            z = obj.ImageMatrixMemDims(3);
            obj.SuperFilt = zeros(obj.ImageMatrixMemDims,'single');
            obj.SuperFilt(x/2-fwidx/2+1:x/2+fwidx/2,y/2-fwidy/2+1:y/2+fwidy/2,z/2-fwidz/2+1:z/2+fwidz/2) = F0;
        end
        
%==================================================================
% ReturnAllSetup
%==================================================================   
        function ReturnAllSetup(obj,log)
            %log.info('Allocate CPU Memory');
            if strcmp(obj.StitchMetaData.ImageType,'complex')
                obj.Image = complex(zeros([obj.ImageMatrixMemDims,obj.ReconGpuBatchRxLen],obj.StitchMetaData.ImagePrecision),0);
            elseif strcmp(obj.StitchMetaData.ImageType,'abs')
                obj.Image = zeros([obj.ImageMatrixMemDims,obj.ReconGpuBatchRxLen],obj.StitchMetaData.ImagePrecision);
            end
        end  
              
%==================================================================
% ReturnAllImages
%==================================================================         
        function ReturnAllImages(obj,log)            
            %log.info('Return Images from GPU');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    FullImage = obj.ReturnOneImageMatrixGpuMem(GpuNum,GpuChan);
                    obj.Image(:,:,:,ChanNum) = obj.ReturnFoV(FullImage);
                end
            end
        end  
        
%==================================================================
% StitchFreeGpuMemory
%==================================================================           
        function StitchFreeGpuMemory(obj) 
            obj.ReleaseGriddingGpuMem;
            obj.ReleaseSuperGpuMem;
        end   

%==================================================================
% ReleaseSuperGpuMem
%==================================================================           
        function ReleaseSuperGpuMem(obj) 
            if not(isempty(obj.HSuperFilt))
                obj.FreeSuperFiltGpuMem;
            end
            if not(isempty(obj.HSuperLow))
                obj.FreeSuperMatricesGpuMem;
            end
        end   
              
%==================================================================
% InitializeImageArray
%==================================================================          
        function InitializeImageArray(obj,Dim5,Dim6) 
            if strcmp(obj.StitchMetaData.CoilCombine,'Super')
                if strcmp(obj.StitchMetaData.ImageType,'complex')
                    obj.ImageArray = complex(zeros([size(obj.Image),1,Dim5,Dim6],obj.StitchMetaData.ImagePrecision),0);
                elseif strcmp(obj.StitchMetaData.ImageType,'abs')
                    obj.ImageArray = zeros([size(obj.Image),1,Dim5,Dim6],obj.StitchMetaData.ImagePrecision);
                end
            elseif strcmp(obj.StitchMetaData.CoilCombine,'ReturnAll')
                sz = size(obj.Image);
                if strcmp(obj.StitchMetaData.ImageType,'complex')
                    obj.ImageArray = complex(zeros([sz(1:3),obj.StitchMetaData.RxChannels,Dim5,Dim6],obj.StitchMetaData.ImagePrecision),0);
                elseif strcmp(obj.StitchMetaData.ImageType,'abs')
                    obj.ImageArray = zeros([sz(1:3),obj.StitchMetaData.RxChannels,Dim5,Dim6],obj.StitchMetaData.ImagePrecision);
                end    
            end
        end  

%==================================================================
% BuildImageArray
%==================================================================            
        function BuildImageArray(obj,Dim4,Dim5,Dim6)
            if strcmp(obj.StitchMetaData.ImageType,'complex')
                obj.ImageArray(:,:,:,Dim4,Dim5,Dim6) = obj.Image;
            elseif strcmp(obj.StitchMetaData.ImageType,'abs')
                obj.ImageArray(:,:,:,Dim4,Dim5,Dim6) = abs(obj.Image);
            end
        end

%==================================================================
% StitchReturnImage
%==================================================================           
        function Image = StitchReturnImage(obj,log) 
            %Image = obj.ImageArray;
            %--
            obj.ImageArray = permute(obj.ImageArray,[2 1 3 4 5 6 7]);
            Image = flip(obj.ImageArray,2);
            %--
        end  

%==================================================================
% Destructor
%================================================================== 
        function delete(obj)
            obj.StitchFreeGpuMemory;
        end 

    end
end