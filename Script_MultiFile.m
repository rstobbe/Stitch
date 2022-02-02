%================================================================
%  Stitch reconstruction script example
%     - this can be modified for batch processing etc.
%================================================================

%----------------------------------------------------------------
% Define the data path and file
%----------------------------------------------------------------

[fn, pth] = uigetfile('*.dat', 'Choose raw files', 'MultiSelect', 'on');


%%JGG Sept 15, 2017
if(~iscell(fn))
    temp=fn;
    fn={};
    fn{1}=temp;
end

DataPath = pth;

%%

%SavePath = 'E:\Yarnball\Testing\';
%SavePath = 'Y:\ThompsonLab\studies\Lung_T1\YB\';
SavePath = 'Z:\ThompsonLab\studies\HC\Lung\Reconstructed\';
%SavePath = 'Y:\ThompsonLab\studies\Lung_Cart_UTE\2022_01_19_spoilTest\';
Suffix = '_Vent';
%Suffix = '';

for(stud=1:numel(fn))
    
    DataFile = fn{stud};
    %----------------------------------------------------------------
    % Remove previous reconstruction ('Handler') objects if they exist
    %----------------------------------------------------------------
    disp('=====================================================================');
    disp(['Reconstruct ',DataPath,DataFile]);
    if exist('Handler','class')
        delete(Handler);
    end
    
    %----------------------------------------------------------------
    % The RwsSiemensHandler is intended for local *.dat files.
    %   This is currently the only supported 'Handler'
    %----------------------------------------------------------------
    Handler = RwsSiemensHandler();
    
    %----------------------------------------------------------------
    % The RwsSiemensHandler supports other reconstructions.
    %   'SetStitch' defines a Stitch reconstruction.
    %----------------------------------------------------------------
    Handler.SetStitch;
    
    %----------------------------------------------------------------
    % Load reconstruction information from the 'Recon' file.  Note
    %   that the ReconMetaData structure can also be modified from the
    %   Matlab command line if desired.
    %----------------------------------------------------------------
    ReconMetaData = Recon();
    
    %----------------------------------------------------------------
    % These methods load/setup/and process data.
    %----------------------------------------------------------------
    Handler.LoadData([DataPath,DataFile],ReconMetaData);
    Handler.ProcessSetup(ReconMetaData);
    Handler.Process;
    
    %----------------------------------------------------------------
    % Data is currently saved in a format intended for the
    %   MRI software tool labelled 'Compass' (https://github.com/rstobbe/Compass)
    %   The 'Suffix' is appended onto the end of the reconstructed image file.
    %----------------------------------------------------------------
    Handler.SaveImageCompass(SavePath,Suffix);
    
end
