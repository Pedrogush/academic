

function test_svd(k,n,m)
E = zeros(n,m);
Em = E'*E;
svd(Em)

for i=1:k
A = randn(n,m);
Am= A'*A;
if min(svd(Am+Em))>min(svd(Em))
    Em = Em+Am;
end



end
svd(Em)

end