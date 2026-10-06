function aula_18_08_2016()
%aula de sistemas lineares referente ao dia 18 de agosto de 2016
%Funções de Transferênia em Sistemas de Tempo Discreto

%Y(z) == G(z)*U(z)

%Para sistemas de parâmetros concentrados causais:

%G(z) == N(z)/D(z) (G(z) é uma função de transferência racional, razão entre
%dois polinômios)

%N(z) e D(z) são polinômios em z om respectio graus m,n tal que m<=n. Em
%geral:

%N(z) == b_0*z.^m+b_1*z.^(m-1)+...+b_(m-1)*z+b_m;
%D(z) == z.^n    +a_1*z.^(n-1)+...+a_(n-1)*z+a_n;
%obs: a_0 == 1 normalmente por convenção, mas pode ser diferente

%As m raízes finitas de N(z) são chamadas de zeros do sistema, tais que
%N(z*)==0;

%As n raízes finitas de D(z) são chamadas de polos do sistema, tais que
%D(z*)==0;

%G(z) = N(z)/D(z); Z.^(-1){G(z)} = g(k) (resposta ao impulso do sistema)

%obs: D(z) = PRODUTORIO(z-lambda_k), k=1:n;

%G(z)/z = SOMATORIO(a_i/z-lambda_i), k=1:n; 
%obs: considerando inicialmente que lambda_i~=lambda_j,j~=i;

%-> g(k) = SOMATORIO(a_i*lambda_i.^k), k=1:n;

x_ex1(2,1) = 0

for k=1:20
    
end



end