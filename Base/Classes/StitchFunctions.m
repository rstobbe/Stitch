%================================================================
%  
%================================================================

classdef StitchFunctions < Grid & ReturnFov

    properties (SetAccess = private)
        Image;
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
% Initialize
%==================================================================   
        function Initialize(obj,Options,log)
            obj.StitchFreeGpuMemory(log);
            obj.GpuInit(Options.Gpus2Use);
            obj.GridKernelLoad(Options,log);
            obj.InvFiltLoad(Options,log);
            obj.FftInitialize(Options,log);
        end            

%==================================================================
% InitializeCoilCombine
%==================================================================   
        function InitializeCoilCombine(obj,Options,log)
            if strcmp(Options.CoilCombine,'Super')
                obj.SuperSetup(Options,log);
            end
            if strcmp(Options.CoilCombine,'ReturnAll') || strcmp(Options.CoilCombine,'Single')
                obj.ReturnAllSetup(Options,log);
            end
        end        
        
%==================================================================
% StitchGridDataBlock 
%================================================================== 
        function StitchGridDataBlock(obj,ReconInfoMat,DataBlock,log)           
            obj.GpuGrid(ReconInfoMat,DataBlock,log);
        end

%==================================================================
% StitchGridDataBlockFullKern 
%================================================================== 
        function StitchGridDataBlockFullKern(obj,ReconInfoMat,DataBlock,log)           
            obj.GpuGridFullKern(ReconInfoMat,DataBlock,log);
        end   
        
%==================================================================
% StitchGridDataBlockComplexKern 
%================================================================== 
        function StitchGridDataBlockComplexKern(obj,ReconInfoMat,DataBlock,log)           
            obj.GpuGridComplexKern(ReconInfoMat,DataBlock,log);
        end          

%==================================================================
% StitchGridDataBlockCornice
%================================================================== 
        function StitchGridDataBlockCornice(obj,ReconInfoMat,DataBlock,log)           
            obj.GpuGridCornice(ReconInfoMat,DataBlock,log);
        end           
        
%==================================================================
% StitchFft
%================================================================== 
        function StitchFft(obj,Options,log)           
            log.trace('Fourier Transform');
            Scale = Options.IntensityScale;  
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
% StitchFftCornice
%================================================================== 
        function StitchFftCornice(obj,Options,log)           
            log.trace('Fourier Transform');
            Scale = Options.IntensityScale;  
            GpuChan = 1;
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.KspaceScaleCorrect(GpuNum,GpuChan); 
                obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                obj.InverseFourierTransform(GpuNum,GpuChan);
                obj.ImageFourierTransformShift(GpuNum,GpuChan);          
                obj.MultInvFilt(GpuNum,GpuChan);
                obj.ScaleImage(GpuNum,GpuChan,Scale); 
            end
        end         
        
%==================================================================
% StitchFftCorniceNoInvFilt
%================================================================== 
        function StitchFftCorniceNoInvFilt(obj,Options,log)           
            log.trace('Fourier Transform');
            Scale = Options.IntensityScale;  
            GpuChan = 1;
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.KspaceScaleCorrect(GpuNum,GpuChan); 
                obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                obj.InverseFourierTransform(GpuNum,GpuChan);
                obj.ImageFourierTransformShift(GpuNum,GpuChan);          
                obj.ScaleImage(GpuNum,GpuChan,Scale); 
            end
        end                
        
%==================================================================
% StitchFftNoInvFilt
%================================================================== 
        function StitchFftNoInvFilt(obj,Options,log)           
            log.trace('Fourier Transform');
            Scale = Options.IntensityScale;  
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.KspaceScaleCorrect(GpuNum,GpuChan); 
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                    obj.InverseFourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);          
                    obj.ScaleImage(GpuNum,GpuChan,Scale); 
                end
            end
        end    

%==================================================================
% KspaceFourierTransformShiftAll
%================================================================== 
        function KspaceFourierTransformShiftAll(obj,Options,log)           
            log.trace('Kspace Fourier Transform Shift');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                end
            end
        end              

%==================================================================
% KspaceFourierTransformShiftAllCornice
%================================================================== 
        function KspaceFourierTransformShiftAllCornice(obj,Options,log)           
            log.trace('Kspace Fourier Transform Shift');
            GpuChan = 1;
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
            end
        end          
        
%==================================================================
% StitchFftCombine
%================================================================== 
        function StitchFftCombine(obj,Options,log)           
            log.trace('Fourier Transform');
            Scale = Options.IntensityScale;  
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
            log.trace('Combine/Return Images');
            if strcmp(obj.CoilCombine,'Super')
                obj.SuperInit(log);
                obj.SuperCombine(log);
            else
                obj.ReturnAllImages(log);
            end
        end                  

%==================================================================
% SuperSetup
%==================================================================   
        function SuperSetup(obj,Options,log)
            log.trace('Allocate CPU Memory');
            obj.GetFinalMatrixDimensions(Options);
            obj.Image = complex(zeros([obj.ImageReturnDims],'single'),0);
            obj.ImageHighSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);
            obj.ImageLowSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);        
            log.trace('Create/Load Super Filter');
            obj.CreateLoadSuperFilter(Options,log);
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
        function SuperCombine(obj,Options,log)
            log.trace('Super Combine');
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
            log.trace('Finish Super (Return HighSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperHighSoS);
            end
            log.trace('Finish Super (Return LowSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            log.trace('Finish Super (Combine Gpus)');
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,m));
            end
            log.trace('Finish Super (Create Image)');
            FullImage = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            if strcmp(Options.ImageType,'abs')
                FullImage = abs(FullImage);
            end
            FullImage = cast(FullImage,Options.ImagePrecision);
            obj.Image = obj.ReturnFoV(Options,FullImage);
        end        

%==================================================================
% SuperCombinePartial
%================================================================== 
        function SuperCombinePartial(obj,log)
            log.trace('Super Combine Partial');
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
        function SuperCombineFinish(obj,Options,log)
            log.trace('Finish Super Partial (Return HighSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperHighSoS);
            end
            log.trace('Finish Super Partial (Return LowSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            log.trace('Finish Super Partial (Combine Gpus)');
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,m));
            end
            log.trace('Finish Super (Create Image)');
            FullImage = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            if strcmp(Options.ImageType,'abs')
                FullImage = abs(FullImage);
            end
            FullImage = cast(FullImage,Options.ImagePrecision);
            obj.Image = obj.ReturnFoV(Options,FullImage);
        end
                 
%==================================================================
% CreateLoadSuperFilter
%==================================================================         
        function CreateLoadSuperFilter(obj,Options,log)
            log.trace('Create Super Filter');
            fwidx = 2*round((Options.Fov/Options.SuperProfRes)/2);
            fwidy = 2*round((Options.Fov/Options.SuperProfRes)/2);
            fwidz = 2*round((Options.Fov/Options.SuperProfRes)/2);
            F0 = Kaiser_v1b(fwidx,fwidy,fwidz,Options.SuperProfFilt,'unsym');
            x = obj.ImageMatrixMemDims(1);
            y = obj.ImageMatrixMemDims(2);
            z = obj.ImageMatrixMemDims(3);
            obj.SuperFilt = zeros(obj.ImageMatrixMemDims,'single');
            obj.SuperFilt(x/2-fwidx/2+1:x/2+fwidx/2,y/2-fwidy/2+1:y/2+fwidy/2,z/2-fwidz/2+1:z/2+fwidz/2) = F0;
        end
        
%==================================================================
% ReturnAllSetup
%==================================================================   
        function ReturnAllSetup(obj,Options,log)
            log.trace('Allocate CPU Memory');
            obj.GetFinalMatrixDimensions(Options);
            ReconGpuBatchRxLen = obj.ChanPerGpu * obj.NumGpuUsed;
            if strcmp(Options.ImageType,'complex')
                obj.Image = complex(zeros([obj.ImageReturnDims,ReconGpuBatchRxLen],Options.ImagePrecision),0);
            elseif strcmp(Options.ImageType,'abs')
                obj.Image = zeros([obj.ImageReturnDims,ReconGpuBatchRxLen],Options.ImagePrecision);
            end
        end  

%==================================================================
% SingleImageSetup
%==================================================================   
        function SingleImageSetup(obj,Options,log)
            log.trace('Allocate CPU Memory');
            obj.GetFinalMatrixDimensions(Options);
            if strcmp(Options.ImageType,'complex')
                obj.Image = complex(zeros(obj.ImageReturnDims,Options.ImagePrecision),0);
            elseif strcmp(Options.ImageType,'abs')
                obj.Image = zeros(obj.ImageReturnDims,Options.ImagePrecision);
            end
        end         
        
%==================================================================
% ReturnAllImages
%==================================================================         
        function ReturnAllImages(obj,Options,log)            
            log.trace('Return Images from GPU');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    FullImage = obj.ReturnOneImageMatrixGpuMem(GpuNum,GpuChan);
                    if strcmp(Options.ImageType,'abs')
                        FullImage = abs(FullImage);
                    end
                    FullImage = cast(FullImage,Options.ImagePrecision);
                    obj.Image(:,:,:,ChanNum) = obj.ReturnFoV(Options,FullImage);
                end
            end
        end  

%==================================================================
% ReturnAllImagesCornice
%==================================================================         
        function ReturnAllImagesCornice(obj,Options,log)            
            log.trace('Return Images from GPU');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                FullImage = obj.ReturnOneImageMatrixGpuMem(GpuNum,1);
                if strcmp(Options.ImageType,'abs')
                    FullImage = abs(FullImage);
                end
                FullImage = cast(FullImage,Options.ImagePrecision);
                obj.Image(:,:,:,m) = obj.ReturnFoV(Options,FullImage);
            end
        end          
        
%==================================================================
% ReturnAllKspace
%==================================================================         
        function ReturnAllKspace(obj,Options,log)            
            log.trace('Return kSpace from GPU');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    FullImage = obj.ReturnOneKspaceMatrixGpuMem(GpuNum,GpuChan);
                    if strcmp(Options.ImageType,'abs')
                        FullImage = abs(FullImage);
                    end
                    FullImage = cast(FullImage,Options.ImagePrecision);
                    obj.Image(:,:,:,ChanNum) = obj.ReturnFoV(Options,FullImage);
                end
            end
        end         

%==================================================================
% ReturnAllKspaceCornice
%==================================================================         
        function ReturnAllKspaceCornice(obj,Options,log)            
            log.trace('Return Images from GPU');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                FullImage = obj.ReturnOneKspaceMatrixGpuMem(GpuNum,1);
                if strcmp(Options.ImageType,'abs')
                    FullImage = abs(FullImage);
                end
                FullImage = cast(FullImage,Options.ImagePrecision);
                obj.Image(:,:,:,m) = obj.ReturnFoV(Options,FullImage);
            end
        end         
        
%==================================================================
% StitchFreeGpuMemory
%==================================================================           
        function StitchFreeGpuMemory(obj,log) 
            log.trace('Free GPU Memory');
            obj.ReleaseGriddingGpuMem;
            obj.ReleaseSuperGpuMem;
        end   
        
%==================================================================
% StitchFreeGpuMemoryCornice
%==================================================================           
        function StitchFreeGpuMemoryCornice(obj,log) 
            log.trace('Free GPU Memory');
            obj.ReleaseGriddingCorniceGpuMem;
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
% Destructor
%================================================================== 
        function delete(obj)
            obj.ReleaseGriddingGpuMem;
            obj.ReleaseSuperGpuMem;
        end 

    end
end