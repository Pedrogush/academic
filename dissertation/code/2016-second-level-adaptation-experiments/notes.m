%RSF (Real Schur Form)
%problema do autovalor: converter a matriz para forma real de schur através
%de decomposição QR sucessiva

%autovetores vem na forma normalizada no comando eig

%V'*V é ortogonal no caso em que M = M', o produto interno dos autovetores
%é 0

%xAx/xA2x < Ts*gamma

%x(sum lambdai ki xi) / (sum lambdai ki xi) (sum lambdai ki xi) < Tsgamma
%x = sum ki xi, onde xi são os autovetores de A e x um vetor genérico
%sujeito a norma x <=1
%x = VK, K= V-1*x
%(k1x1+k2x2+...+knxn)(lambda1k1x1+lambda2k2x2+...+lambdanknxn)/(lambda1k1x1+lambda2k2x2+...+lambdanknxn)^2<Ts*gamma
%(lambda1*k1^2+lambda2*k2^2+...+lambdankn^2)/(lambda1^2k1^2+...+lambdan^2*kn^2)
%sum(lambdai*ki^2)/sum(lambdai^2*ki^2)
%K'*L*K/K'*L^2*K, onde K é fatoracao de x na base dos autovetores
% não temos   x'*V*L*V'*x/x'*V*L^2*V'*x C< Tsgamma
%max(polyeig(VLV',VL2V'*tsgamma))

%outra abordagem: derivar em relação a x e igualar a 0
%procurar tabela de derivada de (x^2 + C1/x^2+C2), montar o gradiente