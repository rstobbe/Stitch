%================================================================
%  
%================================================================

classdef StitchReconStandardSodium < StitchReconSimple

    properties (SetAccess = private)                    
        ImageArray;
        CurAverage;
        TrajAcqStart;
        TrajAcqStop;
        DataTestArray;
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconStandardSodium()
            obj@StitchReconSimple;
        end
        
%==================================================================
% StitchInit 
%==================================================================   
        function StitchInit(obj,StitchMetaData,ReconInfoMat,log)
            obj.StitchBasicInit(StitchMetaData,ReconInfoMat,log);          
        end
        
%==================================================================
% UpdateStitchMetaData (subclass)
%==================================================================          

%==================================================================
% StitchReconDataProcessInit
%==================================================================  
        function StitchReconDataProcessInit(obj,DataObj,log) 
            log.info('Initialize Gridding');
            obj.StitchGridInit(log);  
            obj.CurAverage = 1;
            obj.TrajAcqStart = 1;
            obj.TrajAcqStop = DataObj.DataBlockLength;
            obj.ImageArray = [];
            obj.DataTestArray = zeros(1,DataObj.TotalBlockReads*DataObj.DataBlockLength);
        end      

%==================================================================
% StitchIntraAcqProcess
%==================================================================           
        function StitchIntraAcqProcess(obj,DataObj,log)
            if strcmp(DataObj.ReconHandlerName,'StitchSiemensLocal')
                if DataObj.DataBlockNumber == 1
                    fprintf('\b');
                else
                    fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
                end
                fprintf(' (%02.1d of %02.1d blocks read / gridded)',DataObj.DataBlockNumber,DataObj.TotalBlockReads);
            end
            
            %-----------------------------------------
            % Deal with Dummies
            %-----------------------------------------            
            if obj.StitchMetaData.Dummies > 0
                if obj.TrajAcqStart > obj.TrajAcqStop
                    Array1 = obj.TrajAcqStart:DataObj.AcqsPerImage;
                    Array2 = 1:obj.TrajAcqStop;
                    TrajArray = [Array1 Array2];
                else
                    TrajArray = obj.TrajAcqStart:obj.TrajAcqStop;
                end
                ZeroDataInds = (TrajArray <= obj.StitchMetaData.Dummies);
                DataObj.ZeroData(ZeroDataInds);
            end
            
            %-----------------------------------------
            % Plot Steady State
            %-----------------------------------------    
            figure(234623); clf; hold on;
            obj.DataTestArray((DataObj.DataBlockNumber-1)*DataObj.DataBlockLength+1:DataObj.DataBlockNumber*DataObj.DataBlockLength) = (squeeze(DataObj.DataBlock(1,:,1)) + 1j*squeeze(DataObj.DataBlock(2,:,1)));
            plot(abs(obj.DataTestArray),'k');
            plot(real(obj.DataTestArray),'r');
            plot(imag(obj.DataTestArray),'b');
            title('SteadyState'); xlabel('Trajectory Number'); ylabel('Signal');
            drawnow;
                
            %-----------------------------------------
            % Process
            %-----------------------------------------   
            if DataObj.DataBlockNumber == DataObj.TotalBlockReads
                if strcmp(DataObj.ReconHandlerName,'StitchSiemensLocal')
                    fprintf('\n');
                end
                Info.TrajAcqStart = obj.TrajAcqStart;
                Info.TrajAcqStop = DataObj.AcqsPerImage;     
                obj.StitchGridDataBlock(DataObj,Info,log);
            else
                if obj.TrajAcqStop > DataObj.AcqsPerImage
                    
                    %-----------------------------------------
                    % Finish Last Image
                    %-----------------------------------------
                    TempDataObj.DataBlock = zeros(DataObj.NumCol*2,DataObj.DataBlockLength,DataObj.RxChannels,'single');
                    Info.TrajAcqStart = obj.TrajAcqStart;
                    Info.TrajAcqStop = DataObj.AcqsPerImage; 
                    Start = 1;
                    Stop = Info.TrajAcqStop - Info.TrajAcqStart + 1;
                    TempDataObj.DataBlock(:,Start:Stop,:) = DataObj.DataBlock(:,Start:Stop,:);
                    TempDataObj.DataBlockLength = DataObj.DataBlockLength;
                    TempDataObj.NumCol = DataObj.NumCol;
                    obj.StitchGridDataBlock(TempDataObj,Info,log);
                    obj.StitchFft(log);
                    if obj.CurAverage == 1
                        Image = obj.StitchReturnIndividualImages;
                        NumExp = 1;
                        NumEchos = 1;
                        obj.ImageArray = complex(zeros([size(Image(1:3)),1,NumExp,DataObj.NumAverages,NumEchos],'single'),0);
                    end
                    obj.ImageArray(:,:,:,:,:,obj.CurAverage,:) = obj.StitchReturnIndividualImages;
                    obj.CurAverage = obj.CurAverage + 1;
                    obj.DataTestArray = zeros(1,DataObj.TotalBlockReads*DataObj.DataBlockLength);
                    
                    %-----------------------------------------
                    % Start New Image
                    %-----------------------------------------
                    obj.StitchGridInit(log);    % maybe version that doesn't do full init?
                    TempDataObj.DataBlock = zeros(DataObj.NumCol*2,DataObj.DataBlockLength,DataObj.RxChannels,'single');
                    Info.TrajAcqStart = 1;
                    Info.TrajAcqStop = DataObj.AcqsPerImage - Info.TrajAcqStart + 1; 
                    StartData = Stop + 1;
                    StopData = DataObj.DataBlockLength;
                    TempDataObj.DataBlock(:,Info.TrajAcqStart:Info.TrajAcqStop,:) = DataObj.DataBlock(:,StartData:StopData,:);
                    TempDataObj.DataBlockLength = DataObj.DataBlockLength;
                    TempDataObj.NumCol = DataObj.NumCol;
                    obj.StitchGridDataBlock(TempDataObj,Info,log);
                    obj.TrajAcqStart = obj.TrajAcqStart + DataObj.DataBlockLength;
                    obj.TrajAcqStop = obj.TrajAcqStop + DataObj.DataBlockLength;
                else
                    Info.TrajAcqStart = obj.TrajAcqStart;
                    Info.TrajAcqStop = obj.TrajAcqStop;                  
                    obj.StitchGridDataBlock(DataObj,Info,log);
                    obj.TrajAcqStart = obj.TrajAcqStart + DataObj.DataBlockLength;
                    obj.TrajAcqStop = obj.TrajAcqStop + DataObj.DataBlockLength;
                end    
            end     
        end        
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,DataObj,log)
            obj.StitchFft(log);
            obj.ImageArray(:,:,:,:,:,obj.CurAverage,:) = obj.StitchReturnIndividualImages;
        end

%==================================================================
% StitchReturnImage
%==================================================================           
        function Image = StitchReturnImage(obj,log) 
            Image = obj.ImageArray;
        end            

%==================================================================
% Destructor
%================================================================== 
        function delete(obj)
            obj.StitchFreeGpuMemory;
        end         

    end
end
