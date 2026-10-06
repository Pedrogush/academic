function [convhull, alpha] = gen_randconvhull_minphase(n, theta)
m = n+1;
convhull = zeros(n,m);
radius = 2*norm(theta);

while isinconvhull(convhull,theta)~=1
    convhull_b = radius*randn(n/2,m);
    convhull_a = radius*randn(n/2,m);
    for j=1:m
        for i=1:n/2
            if sign(convhull_b(i,j))<0
                convhull_b(i,j)=-convhull_b(i,j);
            end
        end
    end            
convhull = [convhull_b; convhull_a];
end
alpha = [convhull; ones(1, m)]^-1*[theta; 1];
alpha = alpha(1:length(alpha-1));

end

