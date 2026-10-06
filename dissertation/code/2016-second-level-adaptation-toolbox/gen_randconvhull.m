function [convhull, alpha] = gen_randconvhull(n, theta)
m = n+1;
convhull = zeros(n,m);
radius = 2*norm(theta);

while isinconvhull(convhull,theta)~=1
convhull = radius*randn(n,m);
end
alpha = [convhull; ones(1, m)]^-1*[theta; 1];
alpha = alpha(1:length(alpha-1));

end

