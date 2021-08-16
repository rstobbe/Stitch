%================================================================
%  
%================================================================

classdef ReturnAll < ReturnFov

    properties (SetAccess = private)                    
        Image;
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = ReturnAll()
        end

%==================================================================
% ReturnAllSetup
%==================================================================   
        function ReturnAllSetup(obj,log)
            log.info('Allocate CPU Memory');
            if strcmp(obj.StitchMetaData.ImageType{1},'complex')
                obj.Image = complex(zeros([obj.ImageMatrixMemDims,obj.StitchMetaData.RxChannels],'single'),0);
            elseif strcmp(obj.StitchMetaData.ImageType{1},'abs')
                obj.Image = zeros([obj.ImageMatrixMemDims,obj.StitchMetaData.RxChannels],'single');
            end
        end  
        
%==================================================================
% ReturnAllBatchSetup
%==================================================================   
        function ReturnAllBatchSetup(obj,RxPerBatch,log)
            log.info('Allocate CPU Memory');
            if strcmp(obj.StitchMetaData.ImageType{1},'complex')
                obj.Image = complex(zeros([obj.ImageMatrixMemDims,RxPerBatch],'single'),0);
            elseif strcmp(obj.StitchMetaData.ImageType{1},'abs')
                obj.Image = zeros([obj.ImageMatrixMemDims,RxPerBatch],'single');
            end
        end          
        
%==================================================================
% ReturnAllImages
%==================================================================         
        function ReturnAllImages(obj,log)            
            log.info('Return Images from GPU');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    FullImage = obj.ReturnOneImageMatrixGpuMem(GpuNum,GpuChan);
                    obj.Image(:,:,:,ChanNum) = obj.ReturnFoV(FullImage,log);
                end
            end
        end      
    end             
end