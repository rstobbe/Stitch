%==================================================
% 
%==================================================

function [Text] = PanelStruct2Text(PanStruct)

Text = '';
for n = 1:length(PanStruct)
    if isempty(PanStruct(n).label)
        Text = [Text,num2str(PanStruct(n).value),char(10)];
    else
        Text = [Text,PanStruct(n).label,' = ',num2str(PanStruct(n).value),char(10)];
    end
end