%================================================================
%  
%================================================================

classdef StitchReconTrajMash < handle

    properties (SetAccess = private)                    
        TrajMashInfo;
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconTrajMash()
        end
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,ReconObj,DataObj,log)

            log.info('Create TrajMash');
            NeededSeqParams{1} = 'TR';
            NeededSeqParams{2} = 'NumAverages';
            Values = DataObj.ExtractSequenceParams(NeededSeqParams);
            MetaData.TR = Values{1};
            MetaData.NumAverages = Values{2};            
            MetaData.NumTraj = ReconObj.StitchMetaData.NumTraj;
            k0 = squeeze(abs(DataObj.DataBlock(1,:,:) + 1j*DataObj.DataBlock(2,:,:)));
            func = str2func(ReconObj.StitchMetaData.TrajMashFunc);
            TrajMash = func(k0,MetaData);
            obj.TrajMashInfo=TrajMash;
            WeightArr = single(TrajMash.WeightArr);
            sz = size(WeightArr);
            NumImages = sz(2);
            
            ReconObj.InitializeImageArray(NumImages,1);
            nbytes = fprintf('Create Image %i of %i',0,NumImages);
            for m = 1:NumImages
                fprintf(repmat('\b',1,nbytes))
                nbytes = fprintf(' --- Create Image %i of %i ---',m,NumImages);
                ReconObj.SuperInit(log);
                for p = 1:ReconObj.ReconGpuBatches
                    ReconObj.GridInitialize(log);
                    RbStart = (p-1)*ReconObj.ReconGpuBatchRxLen + 1;
                    RbStop = p*ReconObj.ReconGpuBatchRxLen;
                    if RbStop > ReconObj.RxChannels
                        RbStop = ReconObj.RxChannels;
                    end
                    RbSize = ReconObj.ReconGpuBatchRxLen;
                    for n = 1:ReconObj.ReconBlocksPerImage
                        TbStart = (n-1)*ReconObj.ReconBlockLength + 1;
                        TbStop = n*ReconObj.ReconBlockLength;
                        if TbStop > ReconObj.NumTraj
                            TbStop = ReconObj.NumTraj;
                        end
                        TbSize = ReconObj.ReconBlockLength;
                        TempDataObj.DataBlock = DoTrajMash(DataObj.DataBlock,WeightArr(:,m),DataObj.NumAverages,TbStart,TbStop,TbSize,RbStart,RbStop,RbSize);
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
            fprintf(repmat('\b',1,nbytes))
        end  
    end
end
