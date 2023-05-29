%================================================================
%  
%================================================================

classdef BartDataObject < handle

    properties (SetAccess = private)                    
        DataFile 
        DataPath 
        DataName
        DataInfo
        NumTrajs
        RxChannels
        NumAverages
        TotalAcqs
        DataFull
        DataBlock
        FovShift = [0 0 0]
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function obj = BartDataObject(file)
            load(file);
            SampDat = single(permute(ksp_sim,[2 3 1]));
            
            sz = size(SampDat);
            obj.DataFull{1} = zeros(sz(1)*2,sz(2),'single');
            obj.DataFull{1}(1:2:end-1,:) = single(real(SampDat));
            obj.DataFull{1}(2:2:end,:) = single(imag(SampDat));

            % NumTrajs / RxChannels / NumAverages should be the same for all
            sz = size(obj.DataFull{1});
            obj.NumTrajs = sz(2);
            if length(sz) == 2
                obj.RxChannels = 1;
                obj.NumAverages = 1;
            elseif length(sz) == 3
                obj.RxChannels = sz(3);
                obj.NumAverages = 1;
            elseif length(sz) == 4
                obj.RxChannels = sz(3);
                obj.NumAverages = sz(4);
            end
            obj.TotalAcqs = obj.NumTrajs * obj.NumAverages;
            
            obj.DataFile = file;
            obj.DataPath = strtok(file,'.');
            obj.DataName = 'Test';
            
            obj.DataInfo.ExpPars = '';
            obj.DataInfo.ExpDisp = '';
            obj.DataInfo.PanelOutput = '';
            obj.DataInfo.Seq = 'BartSim';
            obj.DataInfo.Protocol = file;
            obj.DataInfo.VolunteerID = 'Test';
            obj.DataInfo.TrajName = '';
            obj.DataInfo.TrajImpName = '';
            obj.DataInfo.RxChannels = 1;
            obj.DataInfo.SimSampZeroFill = 256;     % unknown
        end
        
%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj,Options)
            if strcmp(Options.IntensityScale,'Default')
                Scale = (Options.ZeroFill/obj.DataInfo.SimSampZeroFill)^3;
                Options.SetIntensityScale(Scale);
            end      
        end
 
%==================================================================
% ReadDataBlock
%================================================================== 
        function ReadDataBlock(obj,Trajs,Rcvrs,AveNum,AcqNum,AcqInfo,Log)        
            %obj.DataBlock = obj.DataFull{AcqNum}(:,Trajs,Rcvrs,AveNum);
            obj.DataBlock = obj.DataFull{AcqNum}(1:2*AcqInfo.NumCol,Trajs,Rcvrs,AveNum);     % Facilitate LowResExtract
        end
            
    end
end