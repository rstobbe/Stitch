%====================================================
% 
%       
%====================================================

function Filt = Kaiser_v1b(x,y,z,beta,type)

if strcmp(type,'unsym')
    x = x+1;
    y = y+1;
    z = z+1;
end

Filtx = zeros(x,y,z);
for a = 1:y 
    for b = 1:z
        Filtx(:,a,b) = kaiser(x,beta);
    end
end

Filty = zeros(x,y,z);
for a = 1:x 
    for b = 1:z
        Filty(a,:,b) = kaiser(y,beta);
    end
end

Filtz = zeros(x,y,z);
for a = 1:x 
    for b = 1:y
        Filtz(a,b,:) = kaiser(z,beta);
    end
end

Filt = Filtx .* Filty .* Filtz;

if strcmp(type,'unsym')
    Filt = Filt(1:x-1,1:y-1,1:z-1);
end