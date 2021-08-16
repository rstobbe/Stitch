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
            obj.SetStitchMetaData('DataSource','SiemensLocal');
        end 
     
%==================================================================
% Prepare
%==================================================================   
        function Prepare(obj,ReconMetaData,log)       
            if ReconMetaData.UseLocal
                obj.SetStitchMetaDataStruct(ReconMetaData);
            end
            if ReconMetaData.LoadTrajectoryLocal
                obj.LoadTrajectoryLocal(log);
            end
        end         
        
%==================================================================
% ProcessSiemensHeaderInfo
%==================================================================           
        function ProcessSiemensHeaderInfo(obj,DataObj,log)
            sWipMemBlock = DataObj.DataHdr.sWipMemBlock;
            ReconMetaData.Protocol = DataObj.DataHdr.ProtocolName;
            ReconMetaData.RxChannels = DataObj.DataDims.NCha;
            ReconMetaData = InterpTrajSiemens(obj,ReconMetaData,sWipMemBlock);   
            obj.SetStitchMetaDataStruct(ReconMetaData);
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
% ProcessSetup
%==================================================================             
        function ProcessSetup(obj,ReconMetaData,log)
            if ~isfield(ReconMetaData,'LoadTrajectoryLocal')
                ReconMetaData.LoadTrajectoryLocal = 1;
            end
            if ReconMetaData.LoadTrajectoryLocal
                if not(strcmp(ReconMetaData.TrajFile,obj.StitchMetaData.TrajFile))
                    obj.LoadTrajectoryLocal(log);
                end
            end
            obj.SetStitchMetaDataStruct(ReconMetaData);
            obj.StitchFullInit(log)
        end         

%==================================================================
% PostAcqProcess
%==================================================================   
        function PostAcqProcess(obj,DataObj,log)
            obj.StitchPostAcqProcess(DataObj,log);
        end        
        
%==================================================================
% IntraAcqProcess
%==================================================================   
        function IntraAcqProcess(obj,DataObj,log)                 
            obj.StitchIntraAcqProcess(DataObj,log); 
        end

%==================================================================
% FinishAcqProcess
%==================================================================   
        function FinishAcqProcess(obj,DataObj,log)
            obj.StitchFinishAcqProcess(DataObj,log);
        end        
        
%==================================================================
% ReturnImage
%==================================================================   
        function Image = ReturnImage(obj,log)
            Image = obj.StitchReturnImage(log);
        end        
        
%==================================================================
% InterpTrajSiemens
%   ** sWipMemBlock should contain all necesarry ReconMetaData
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
%             ReconMetaData.Fov = Fov;
%             ReconMetaData.Vox = Vox;
%             ReconMetaData.Elip = Elip;
%             ReconMetaData.Tro = Tro/10;
%             ReconMetaData.Nproj = Nproj;
%             ReconMetaData.p = p;
%             ReconMetaData.id = id;
        end

%==================================================================
% Destructor
%================================================================== 
        % done below
        
    end
end
