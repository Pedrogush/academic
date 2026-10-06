
%determinação da F.T de um sensor a partir de dados experimentais, como no
%exemplo, a partir dos dados obtidos de um diagrama de Bode de um sensor de
%posição, tentamos aferir a F.T do sensor estudado

Gain = [4.86 2.356 1.038 0.382 0.074 0.016];
Phase = [-99.43 -106.53 -121.13 -139.85 -164.46 -171.89];
w = [1.57 3.14 6.28 12.57 31.42 62.83];
H = Gain(:).*exp(1i*Phase(:)*pi/180);
[B, A] = invfreqs(H, w, 0, 2)
tf(B, A)