
function rampa(stoptime,passo)
endk = floor(stoptime/passo)
t= 0
x= 0
d= 0
r= 1
for k=1:endk
   t(k+1) = t(k) + passo;
   x(k+1) = x(k) + 0.1*passo; 
end
plot(t,x)