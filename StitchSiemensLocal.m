%================================================================
%  
%================================================================

classdef StitchSiemensLocal < StitchRecon
    
    properties (SetAccess = private)                    
    end    
    methods

%==================================================================
% Constructor
%==================================================================   
        function obj = StitchSiemensLocal()
            obj@StitchRecon();          
        end 

%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj,ReconMetaData,log)       
            ReconMetaData.DataSource = 'SiemensLocal';
            ReconMetaData.PullReconLocal = 0;               % already read 
            ReconMetaData.LoadTrajLocal = 1;
            obj.StitchInit(ReconMetaData,log); 
        end
        
%==================================================================
% ProcessSiemensHeaderInfo
%==================================================================           
        function ProcessSiemensHeaderInfo(obj,RwsSiemensHandler,log)
            sWipMemBlock = RwsSiemensHandler.DataHdr.sWipMemBlock;
            ReconMetaData.Protocol = RwsSiemensHandler.DataHdr.ProtocolName;
            ReconMetaData.RxChannels = RwsSiemensHandler.DataDims.NCha;
            ReconMetaData = InterpTrajSiemens(obj,ReconMetaData,sWipMemBlock);   
            obj.UpdateTestStitchMetaData(ReconMetaData,log);
        end

%==================================================================
% LocalDataBlockInit
%==================================================================          
        function LocalDataBlockInit(obj,RwsSiemensHandler,log)
            obj.StitchGridInit(RwsSiemensHandler,log);
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
            obj.StitchIntraAcqProcess(RwsSiemensHandler,log); 
        end

%==================================================================
% PostAcqProcess
%==================================================================   
        function PostAcqProcess(obj,RwsSiemensHandler,log)
            obj.StitchPostAcqProcess(RwsSiemensHandler,log);
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
        
    end
end
