function bool = isinconvhull( convhull,theta )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
warning('off','MATLAB:singularMatrix')
    m = length(convhull);
    alfa_sup = [convhull; ones(1,m)]^-1*[theta; 1];
    up = alfa_sup(1:m)<1;
    bottom = alfa_sup(1:m)>0;
    
    if bottom(1:m)'*ones(m,1)==m && up(1:m)'*ones(m,1)==m &&  alfa_sup'*ones(m,1)==1
        bool=1;
    else
        bool=0;
    end    
    warning('on','MATLAB:singularMatrix')
end

