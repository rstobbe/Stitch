%================================================================
%  
%================================================================

classdef StitchReconStandard < handle

    properties (SetAccess = private)                    
        TrajMashInfo;
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconStandard()
        end
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,ReconObj,DataObj,log)

            NumImages = DataObj.DataBlockLength / ReconObj.NumTraj;    
            ReconObj.InitializeImageArray(NumImages,1);    
            for m = 1:NumImages
                log.info('Create Image %i of %i',m,NumImages);
                ReconObj.SuperInit(log);
                for p = 1:ReconObj.ReconGpuBatches
                    ReconObj.GridInitialize(log);
                    RbStart = (p-1)*ReconObj.ReconGpuBatchRxLen + 1;
                    RbStop = p*ReconObj.ReconGpuBatchRxLen;
                    if RbStop > ReconObj.RxChannels
                        RbStop = ReconObj.RxChannels;
                    end
                    for n = 1:ReconObj.ReconBlocksPerImage
                        TbStart = (n-1)*ReconObj.ReconBlockLength + 1;
                        TbStop = n*ReconObj.ReconBlockLength;
                        if TbStop > ReconObj.NumTraj
                            TbStop = ReconObj.NumTraj;
                        end
                        Acqs = (m-1)*ReconObj.NumTraj + (TbStart:TbStop);
                        Rcvrs = RbStart:RbStop;
                        if length(Rcvrs) < ReconObj.ReconGpuBatchRxLen
                            TempDataObj.DataBlock = zeros(DataObj.NumCol*2,length(Acqs),ReconObj.ReconGpuBatchRxLen,'single');
                            TempDataObj.DataBlock(:,:,1:length(Rcvrs)) = DataObj.DataBlock(:,Acqs,Rcvrs);
                        else
                            TempDataObj.DataBlock = DataObj.DataBlock(:,Acqs,Rcvrs);
                        end
                        Info.TrajAcqStart = TbStart;
                        Info.TrajAcqStop = TbStop;
                        TempDataObj.DataBlockLength = ReconObj.ReconBlockLength;
                        TempDataObj.NumCol = DataObj.NumCol;
                        ReconObj.StitchGridDataBlock(TempDataObj,Info,log); 
                    end
                    ReconObj.StitchFft(log); 
                    if strcmp(ReconObj.StitchMetaData.CoilCombine,'ReturnAll')
                        ReconObj.ReturnAllImages(log);
                        ReconObj.BuildImageArray((RbStart:RbStop),m,1);
                    elseif strcmp(ReconObj.StitchMetaData.CoilCombine,'Super')
                        ReconObj.SuperCombinePartial(log);
                    end
                end
                if strcmp(ReconObj.StitchMetaData.CoilCombine,'Super')
                    ReconObj.SuperCombineFinish(log);
                    ReconObj.BuildImageArray(1,m,1);
                end
            end
        end  
    end
end
