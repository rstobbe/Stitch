%================================================================
%  
%================================================================

classdef Super < ReturnFov

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
        function [obj] = Super()
            obj@ReturnFov;
        end
        
%==================================================================
% SuperSetup
%==================================================================   
        function SuperSetup(obj,log)
            log.info('Allocate CPU Memory');
            obj.Image = complex(zeros([obj.ImageMatrixMemDims],'single'),0);
            obj.ImageHighSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);
            obj.ImageLowSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);        
            log.info('Create/Load Super Filter');
            obj.CreateLoadSuperFilter(obj.StitchMetaData,log);
            if not(isempty(obj.HSuperFilt))
                obj.FreeSuperFiltGpuMem;
            end
            obj.LoadSuperFiltGpuMem(obj.SuperFilt);
        end   

%==================================================================
% SuperInit
%==================================================================   
        function SuperInit(obj,log)                      
            log.info('Initialize Super');
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
            log.info('Super Combine');
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
            log.info('Finish Super (Return HighSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperHighSoS);
            end
            log.info('Finish Super (Return LowSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            log.info('Finish Super (Combine Gpus)');
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,m));
            end
            log.info('Finish Super (Create Image)');
            obj.Image = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            obj.GetFinalMatrixDimensions;
            obj.Image = obj.ReturnFoV(obj.Image); 
        end        

%==================================================================
% SuperCombinePartial
%================================================================== 
        function SuperCombinePartial(obj,log)
            log.info('Super Combine Partial');
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
            log.info('Finish Super Partial (Return HighSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperHighSoS);
            end
            log.info('Finish Super Partial (Return LowSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            log.info('Finish Super Partial (Combine Gpus)');
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,m));
            end
        end         

%==================================================================
% SuperCombineFinish
%==================================================================         
        function SuperCombineFinish(obj,log)
            log.info('Finish Super (Create Image)');
            obj.Image = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            obj.GetFinalMatrixDimensions;
            obj.Image = obj.ReturnFoV(obj.Image); 
        end
            
%==================================================================
% ReleaseSuperGpuMem
%==================================================================           
        function ReleaseSuperGpuMem(obj,log) 
            if not(isempty(obj.HSuperFilt))
                obj.FreeSuperFiltGpuMem;
            end
            if not(isempty(obj.HSuperLow))
                obj.FreeSuperMatricesGpuMem;
            end
        end          
                      
%==================================================================
% CreateLoadSuperFilter
%==================================================================         
        function CreateLoadSuperFilter(obj,StitchMetaData,log)
            fwidx = 2*round((StitchMetaData.Fov/StitchMetaData.Super.ProfRes)/2);
            fwidy = 2*round((StitchMetaData.Fov/StitchMetaData.Super.ProfRes)/2);
            fwidz = 2*round((StitchMetaData.Fov/StitchMetaData.Super.ProfRes)/2);
            F0 = Kaiser_v1b(fwidx,fwidy,fwidz,StitchMetaData.Super.ProfFilt,'unsym');
            x = obj.ImageMatrixMemDims(1);
            y = obj.ImageMatrixMemDims(2);
            z = obj.ImageMatrixMemDims(3);
            obj.SuperFilt = zeros(obj.ImageMatrixMemDims,'single');
            obj.SuperFilt(x/2-fwidx/2+1:x/2+fwidx/2,y/2-fwidy/2+1:y/2+fwidy/2,z/2-fwidz/2+1:z/2+fwidz/2) = F0;
        end
    end
end