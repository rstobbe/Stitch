%================================================================
%  
%================================================================

classdef StitchFire < StitchRecon & ReturnImage
    
    properties (SetAccess = private)                    
        ReconHandlerName = 'StitchFire';
    end    
    methods

%==================================================================
% Constructor
%==================================================================   
        function obj = StitchFire(RwsFireServer,log)
            
            log.info("Starting StitchFire")
            %------------------------------------------------------
            % Build Objects
            %------------------------------------------------------            
            obj@StitchRecon();
            
            %------------------------------------------------------
            % SiemensMetaData
            %------------------------------------------------------
%             studyInformation = RwsFireServer.MetaData.studyInformation
%             measurementInformation = RwsFireServer.MetaData.measurementInformation
%             acquisitionSystemInformation = RwsFireServer.MetaData.acquisitionSystemInformation
%             experimentalConditions = RwsFireServer.MetaData.experimentalConditions
%             encoding = RwsFireServer.MetaData.encoding
%             sequenceParameters = RwsFireServer.MetaData.sequenceParameters
%             userParameters = RwsFireServer.MetaData.userParameters

            %------------------------------------------------------
            % Interpret RwsFireServer -> Stitch
            %------------------------------------------------------            
            StitchMetaData.DataSource = 'Fire';
            if RwsFireServer.TrajDims == 0
                StitchMetaData.PullReconLocal = 1;
            else
                error('finish')
            end
            StitchMetaData.ReconProtocol = RwsFireServer.StitchProtocolName;
            StitchMetaData.RxChannels = RwsFireServer.MetaData.acquisitionSystemInformation.receiverChannels;
            StitchMetaData = InterpTrajSiemens(obj,StitchMetaData,RwsFireServer.MetaData);
            StitchMetaData.BlockLength = RwsFireServer.AcqsPerPortRead;
            
            %------------------------------------------------------
            % Initialize StitchRecon
            %------------------------------------------------------                 
            obj.StitchInit(StitchMetaData,log);
            obj.UpdateTestStitchMetaData(struct(),log); 
            
            %------------------------------------------------------
            % Port Update
            %------------------------------------------------------  
            PortUpdate.AcqsPerPortRead = obj.StitchMetaData.BlockLength;
            PortUpdate.SampStart = obj.StitchMetaData.SampStart;
            PortUpdate.SampEnd = obj.StitchMetaData.SampEnd;
            PortUpdate.NumCol = obj.StitchMetaData.npro;
            RwsFireServer.InitStitchPortControl(PortUpdate);
            obj.Initialize(RwsFireServer,log);        
        end 

%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj,RwsFireServer,log)              
            obj.StitchDataProcessInit(RwsFireServer,log);     
        end
        
%==================================================================
% IntraAcqProcess
%==================================================================   
        function IntraAcqProcess(obj,RwsFireServer,log)              
            RwsFireServer.CreateDataObject(log);
            obj.StitchIntraAcqProcess(RwsFireServer,log);
        end

%==================================================================
% PostAcqProcess
%==================================================================   
        function PostAcqProcess(obj,RwsFireServer,log)
            obj.StitchPostAcqProcess(RwsFireServer,log);
        end
        
%==================================================================
% InterpTrajSiemens
%==================================================================           
        function StitchMetaData = InterpTrajSiemens(obj,StitchMetaData,SiemensMetaData)
            UserParamsLong = SiemensMetaData.userParameters.userParameterLong;
            UserParamsDouble = SiemensMetaData.userParameters.userParameterDouble;
            if UserParamsLong(3).value == 10
                Type = 'YB';
            elseif UserParamsLong(3).value == 20
                Type = 'TPI';
            end
            Fov = UserParamsLong(21).value; 
            Vox = round(UserParamsLong(22).value * UserParamsLong(23).value * UserParamsLong(24).value / 1e8);
            VoxArr = [UserParamsLong(22).value UserParamsLong(23).value UserParamsLong(24).value];
            ind = find(VoxArr == max(VoxArr),1,'first');
            if ind == 1
                Elip = 100*UserParamsLong(23).value/UserParamsLong(22).value;
            elseif ind == 2
                Elip = 100*UserParamsLong(22).value/UserParamsLong(23).value; 
            elseif ind == 3
                Elip = 100*UserParamsLong(22).value/UserParamsLong(24).value; 
            end
            Tro = round(10*UserParamsDouble(5).value);
            Nproj = UserParamsLong(6).value;
            p = UserParamsLong(25).value;
            if strcmp(Type,'TPI')
                id = UserParamsLong(26).value;
                TrajName = ['TPI_F',num2str(Fov),'_V',num2str(Vox),'_E',num2str(Elip),'_T',num2str(Tro),'_N',num2str(Nproj),'_P',num2str(p),'_ID',num2str(id)];
            elseif strcmp(Type,'YB')
                samptype = UserParamsLong(26).value;
                usamp = round(100*UserParamsDouble(7).value);
                id = UserParamsLong(27).value;
                TrajName = ['YB_F',num2str(Fov),'_V',num2str(Vox),'_E',num2str(Elip),'_T',num2str(Tro),'_N',num2str(Nproj),'_P',num2str(p),'_S',num2str(samptype),num2str(usamp),'_ID',num2str(id)];
            end
            StitchMetaData.TrajName = TrajName;
            StitchMetaData.Fov = Fov;
            StitchMetaData.Vox = Vox;
            StitchMetaData.Elip = Elip;
            StitchMetaData.Tro = Tro/10;
            StitchMetaData.Nproj = Nproj;
            StitchMetaData.p = p;
            StitchMetaData.id = id;
        end

%==================================================================
% ReturnImage
%==================================================================   
        function Image = ReturnImage(obj,log)
            Image = obj.StitchReturnImage(log);
        end            
        
%==================================================================
% ReturnIsmrmImage
%==================================================================  
        function IsmrmImage = ReturnIsmrmImage(obj,log)

            Image = obj.StitchReturnImage(log);
            Image = abs(Image);
            Image = Image/max(Image(:));
            Image = Image .* (32767./max(Image(:)));
            Image = int16(round(Image));            
            
            IsmrmImage = ismrmrd.Image();                       % Format as ISMRMRD image data
            %================================================    
            IsmrmImage.data_ = Image;                           % RWS - Note I made a change inside the ISMRMRD 'Image' class
            %================================================
            % In MATLAB's ISMRMD toolbox, header information is not updated after setting image data
            IsmrmImage.head_.matrix_size(1) = uint16(size(obj.Recon.Image,1));
            IsmrmImage.head_.matrix_size(2) = uint16(size(obj.Recon.Image,2));
            IsmrmImage.head_.matrix_size(3) = uint16(size(obj.Recon.Image,3));
            IsmrmImage.head_.channels       = uint16(1);
            IsmrmImage.head_.data_type      = uint16(ismrmrd.ImageHeader.DATA_TYPE.SHORT);
            IsmrmImage.head_.image_index    = uint16(1);  % This field is mandatory
            % Set ISMRMRD Meta Attributes
            meta = ismrmrd.Meta();
            meta.DataRole     = 'Image';
            meta.WindowCenter = 16384;
            meta.WindowWidth  = 32768;
            IsmrmImage.attribute_string_ = serialize(meta);
            IsmrmImage.head_.attribute_string_len = uint32(length(IsmrmImage.attribute_string_));
        end
    end
end
