%================================================================
%  
%================================================================

classdef CartLungRecon < handle
    
    properties (SetAccess = private)                    
        DataIds;
        DataHeaders;
        Data;
        Image;
    end    
    methods

%==================================================================
% Constructor
%==================================================================   
        function obj = CartLungRecon(RwsFireServer,log)
            log.info("Starting CartLungRecon")
            PortUpdate.AcqsPerPortRead = 500;                   % 500 is default for short TR (probably pick less for longer TR) 
            
            TotalMatrixAcqs = RwsFireServer.NumAverages*RwsFireServer.CartInfo.NumPe1Steps*RwsFireServer.CartInfo.NumPe2Steps;
            PortUpdate.TotalAcqs = 3*floor(TotalMatrixAcqs/69) + TotalMatrixAcqs; 
                    
            RwsFireServer.InitCartPortControl(PortUpdate);
            obj.DataIds = zeros(1,RwsFireServer.TotalBlockReads*RwsFireServer.DataBlockLength);
            obj.DataHeaders = cell(1,RwsFireServer.TotalBlockReads*RwsFireServer.DataBlockLength);
            obj.Data = complex(zeros(RwsFireServer.NumCol,RwsFireServer.TotalBlockReads*RwsFireServer.DataBlockLength,RwsFireServer.RxChannels,'single'),0);
        end 
        
%==================================================================
% IntraAcqProcess
%==================================================================   
        function IntraAcqProcess(obj,RwsFireServer,log)              
            RwsFireServer.CreateDataObject(log);
            start = (RwsFireServer.DataBlockNumber-1)*RwsFireServer.DataBlockLength+1;
            stop = RwsFireServer.DataBlockNumber*RwsFireServer.DataBlockLength;
            obj.DataIds(:,start:stop,:) = RwsFireServer.GetDataBlockIds;
            obj.DataHeaders(:,start:stop,:) = RwsFireServer.GetDataBlockHeaders;
            obj.Data(:,start:stop,:) = RwsFireServer.DataBlock(1:2:end,:,:) + 1j*RwsFireServer.DataBlock(2:2:end,:,:);
        end

%==================================================================
% PostAcqProcess
%==================================================================   
        function PostAcqProcess(obj,RwsFireServer,log)
            %--------------------------------------
            % Create 'Image' from 'Data'
            %--------------------------------------
            error('Nothing Coded');
        end
                
%==================================================================
% ReturnIsmrmImage
%==================================================================  
        function IsmrmImage = ReturnIsmrmImage(obj,log)
            Image0 = abs(obj.Image);
            Image0 = Image0/max(Image0(:));
            Image0 = Image0 .* (32767./max(Image0(:)));
            Image0 = int16(round(Image0));            
            IsmrmImage = ismrmrd.Image();                       
            IsmrmImage.data_ = Image0;                          
            IsmrmImage.head_.matrix_size(1) = uint16(size(obj.Recon.Image,1));
            IsmrmImage.head_.matrix_size(2) = uint16(size(obj.Recon.Image,2));
            IsmrmImage.head_.matrix_size(3) = uint16(size(obj.Recon.Image,3));
            IsmrmImage.head_.channels       = uint16(1);
            IsmrmImage.head_.data_type      = uint16(ismrmrd.ImageHeader.DATA_TYPE.SHORT);
            IsmrmImage.head_.image_index    = uint16(1); 
            meta = ismrmrd.Meta();
            meta.DataRole     = 'Image';
            meta.WindowCenter = 16384;
            meta.WindowWidth  = 32768;
            IsmrmImage.attribute_string_ = serialize(meta);
            IsmrmImage.head_.attribute_string_len = uint32(length(IsmrmImage.attribute_string_));
        end
    end
end
