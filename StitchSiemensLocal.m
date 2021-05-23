%================================================================
%  
%================================================================

classdef StitchSiemensLocal < StitchRecon
    
    properties (SetAccess = private)                    
        ReconMetaData;
    end    
    methods

%==================================================================
% Constructor
%==================================================================   
        function obj = StitchSiemensLocal()
            obj@StitchRecon();          
        end 

%==================================================================
% DataLoadInit
%==================================================================   
        function DataLoadInit(obj,ReconMetaData,log)       
            ReconMetaData.DataSource = 'SiemensLocal';
            ReconMetaData.PullReconLocal = 1;               % do again
            ReconMetaData.LoadTrajLocal = 1;
            obj.StitchLoadTrajInfo(ReconMetaData,log); 
        end        
        
%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj,ReconMetaData,log)       
            ReconMetaData.DataSource = 'SiemensLocal';
            ReconMetaData.PullReconLocal = 1;               % do again
            ReconMetaData.LoadTrajLocal = 1;
            obj.StitchInit(ReconMetaData,log); 
        end
        
%==================================================================
% ProcessSiemensHeaderInfo
%==================================================================           
        function ProcessSiemensHeaderInfo(obj,RwsSiemensHandler,log)
            sWipMemBlock = RwsSiemensHandler.DataHdr.sWipMemBlock;
            obj.ReconMetaData.Protocol = RwsSiemensHandler.DataHdr.ProtocolName;
            obj.ReconMetaData.RxChannels = RwsSiemensHandler.DataDims.NCha;
            obj.ReconMetaData = InterpTrajSiemens(obj,obj.ReconMetaData,sWipMemBlock);   
            obj.UpdateTestStitchMetaData(obj.ReconMetaData,log);
        end

%==================================================================
% LocalDataBlockInit
%==================================================================          
        function LocalDataBlockInit(obj,RwsSiemensHandler,log)
            obj.StitchDataProcessInit(RwsSiemensHandler,log);
        end  

%==================================================================
% GetDataReadInfo
%==================================================================             
        function DataReadInfo = GetDataReadInfo(obj)
            DataReadInfo.ScanDummies = obj.StitchMetaData.Dummies;
            DataReadInfo.SampStart = obj.StitchMetaData.SampStart;
            DataReadInfo.Format = 'SingleArray';                                % other option = 'Complex'. 
            DataReadInfo.NumCol = obj.StitchMetaData.NumCol;
        end 

%==================================================================
% IntraAcqProcess
%==================================================================   
        function IntraAcqProcess(obj,RwsSiemensHandler,log)                 
            obj.UpdateTestStitchMetaData(obj.ReconMetaData,log);
            obj.StitchIntraAcqProcess(RwsSiemensHandler,log); 
        end

%==================================================================
% PostAcqProcess
%==================================================================   
        function PostAcqProcess(obj,RwsSiemensHandler,log,OverRide)
            if nargin == 4
                fields = fieldnames(OverRide);
                for n = 1:length(fields)
                    obj.StitchMetaData.(fields{n}) = ReconMetaData.(fields{n});
                end
            end
            obj.UpdateTestStitchMetaData(obj.ReconMetaData,log);
            obj.StitchPostAcqProcess(RwsSiemensHandler,log);
        end

%==================================================================
% FinishAcqProcess
%==================================================================   
        function FinishAcqProcess(obj,RwsSiemensHandler,log)
            obj.StitchFinishAcqProcess(RwsSiemensHandler,log);
        end        
        
%==================================================================
% ReturnImage
%==================================================================   
        function Image = ReturnImage(obj,log)
            Image = obj.StitchReturnImage(log);
        end        
        
%==================================================================
% InterpTrajSiemens
%==================================================================           
        function ReconMetaData = InterpTrajSiemens(obj,ReconMetaData,sWipMemBlock)
            UserParamsLong = sWipMemBlock.alFree;
            UserParamsDouble = sWipMemBlock.adFree;
            if UserParamsLong{3} == 10
                Type = 'YB';
            elseif UserParamsLong{3} == 20
                Type = 'TPI';
            end
            Fov = UserParamsLong{21}; 
            Vox = round(UserParamsLong{22} * UserParamsLong{23} * UserParamsLong{24} / 1e8);
            VoxArr = [UserParamsLong{22} UserParamsLong{23} UserParamsLong{24}];
            ind = find(VoxArr == max(VoxArr),1,'first');
            if ind == 1
                Elip = 100*UserParamsLong{23}/UserParamsLong{22};
            elseif ind == 2
                Elip = 100*UserParamsLong{22}/UserParamsLong{23}; 
            elseif ind == 3
                Elip = 100*UserParamsLong{22}/UserParamsLong{24}; 
            end
            Tro = round(10*UserParamsDouble{5});
            Nproj = UserParamsLong{6};
            p = UserParamsLong{25};
            if strcmp(Type,'TPI')
                id = UserParamsLong{26};
                TrajName = ['TPI_F',num2str(Fov),'_V',num2str(Vox),'_E',num2str(Elip),'_T',num2str(Tro),'_N',num2str(Nproj),'_P',num2str(p),'_ID',num2str(id)];
            elseif strcmp(Type,'YB')
                samptype = UserParamsLong{26};
                usamp = round(100*UserParamsDouble{7});
                id = UserParamsLong{27};
                TrajName = ['YB_F',num2str(Fov),'_V',num2str(Vox),'_E',num2str(Elip),'_T',num2str(Tro),'_N',num2str(Nproj),'_P',num2str(p),'_S',num2str(samptype),num2str(usamp),'_ID',num2str(id)];
            end
            ReconMetaData.TrajName = TrajName;
            ReconMetaData.Fov = Fov;
            ReconMetaData.Vox = Vox;
            ReconMetaData.Elip = Elip;
            ReconMetaData.Tro = Tro/10;
            ReconMetaData.Nproj = Nproj;
            ReconMetaData.p = p;
            ReconMetaData.id = id;
        end

%==================================================================
% Destructor
%================================================================== 
        % done below
        
    end
end
