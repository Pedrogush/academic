function [tempo,r,r_ponto,eta,u,  ...
          alfa_ponto,alfa_ponto_n1,alfa_n1,x_i_ponto,       ...
          x_m_ponto, x_p_ponto, e_o, norm_2_e_o,            ...
          theta_p_estimativa, x_i, x_p, x_m, theta_i,       ...
          A_i, theta_i_ponto, k_T, alfa_barra, alfa,E,e_i] ...
        = preallocate_memory(n_de_linhas,endk)
%PREALLOCATE_MEMORY Summary of this function goes here
%   Detailed explanation goes here
tempo(endk)=0; 
r(endk+1)=0; 
r_ponto(endk)=0; 
eta(endk+1)=0; 
u(endk)=0;
alfa_ponto(:,endk)=zeros(n_de_linhas,1); 
alfa_ponto_n1(endk)=0; 
alfa_n1(endk)=0; 
x_i_ponto(:,n_de_linhas+1,endk)=zeros(n_de_linhas,1,1);
x_m_ponto(:,endk)=zeros(n_de_linhas,1); 
x_p_ponto(:,endk)=zeros(n_de_linhas,1);
e_o(:,endk)=zeros(n_de_linhas,1); 
norm_2_e_o(endk)=0;
theta_p_estimativa(:,endk)=zeros(n_de_linhas,1);
x_i(:,n_de_linhas+1,endk) = zeros(n_de_linhas,1,1);
x_p(:,endk) = zeros(n_de_linhas,1);
x_m(:,endk) = zeros(n_de_linhas,1);
theta_i(:,n_de_linhas+1,endk) = zeros(n_de_linhas,1,1);
A_i(n_de_linhas,n_de_linhas,n_de_linhas+1,endk) = 0;
theta_i_ponto(:,n_de_linhas+1,1) = zeros(n_de_linhas,1,1);
k_T(:,endk) = zeros(n_de_linhas,1);
alfa_barra(:,endk) = zeros(n_de_linhas+1,1);
alfa(:,endk) = zeros(n_de_linhas,1);
E(:,n_de_linhas,endk)=zeros(n_de_linhas,1,1);
e_i(n_de_linhas,n_de_linhas+1,endk)=0;

end

