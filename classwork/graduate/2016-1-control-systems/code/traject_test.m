%teste de trajetoria para eq do oscilador de van der pol para determinar o
%ciclo limite

function traject_test(mu)
k=0;
for theta=0:0.05:2*pi
    for x1 = -1:0.05:1
    k = k+1;
    if x1~=0
    x2(k) = mu*(sin(theta).^2/cos(2*theta))*(1-x1.^2)/x1;
    else
    x2(k)=0;
    end    
    end
end
plot(x1,x2)
end