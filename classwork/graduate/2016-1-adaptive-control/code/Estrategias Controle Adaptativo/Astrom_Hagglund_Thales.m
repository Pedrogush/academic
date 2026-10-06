function estrutura_de_saida = Astrom_Hagglund_Thales( estrutura_de_entrada )
%ASTROM_HAGGLUND Summary of this function goes here
%   Detailed explanation goes here

[stoptime, h, planta_num,N0,Td0,Ti0,kp0,d0,lim,espera0,r0,M]          ...
 = convert_struct(estrutura_de_entrada);
endk = stoptime/h;
deterioracao = d0;
N = N0;
Td = Td0;
Ti = Ti0;
kp=kp0;
var_aux = 0;
e(1)=0;
tempo(1)=0;
espera = espera0;
u_int_ponto(2,1,1)=0;
u_int(2,1,1)=0;
x_p(2,1,1)=0;
for k=1:endk
    %PID REAL, Espaço de estados, N<<1
    tempo(k+1) = tempo(k)+h;
    r(k+1) = r0;
    [A_pid,b_pid,C_pid,D_pid] = tf2ss(kp*[N*Td*Ti Ti+N*Td 1],[N*Td*Ti Ti 0]);
    if deterioracao==1
        ent_cont(k)=0;
        u_int_ponto(2,1,k)=0;
        u_int(2,1,k)=0;
    else
        ent_cont(k)=e(k);
    end
    
     u_int_ponto(:,1,k) = A_pid*u_int(:,1,k) + b_pid*ent_cont(k);
     u_int(:,1,k+1) = u_int(:,1,k)+h*u_int_ponto(:,1,k);
     u(k)= C_pid*u_int(:,1,k) + D_pid*e(k);
    
    if deterioracao == 1
        if e(k)<0
       u(k)=M;
        else
       u(k)=-M;
        end
    end
    planta_den = [1 2 0];
    
   [A_p,b_p,C_p,D_p] = tf2ss(planta_num,planta_den);  
   x_p_ponto(:,1,k) = A_p*x_p(:,1,k) + b_p*u(k);
   x_p(:,1,k+1) = x_p(:,1,k) + h*x_p_ponto(:,1,k);
   x_p_out(k+1) = C_p*x_p(:,1,k+1)+D_p*u(k);
   
   e(k+1) = r(k+1) - x_p_out(k+1);
   
   if k>1 && deterioracao==0 && abs(e(k))>lim && espera<0;
   deterioracao =1;
   end
   if k>1
       if sign(x_p_out(k+1)-x_p_out(k))~=sign(x_p_out(k)-x_p_out(k-1))
           var_aux = var_aux+1;
           tempos_de_pico(var_aux) = tempo(k);
           X = abs(e(k));
           if var_aux==3;
               Tcr = 2*(tempos_de_pico(2)-tempos_de_pico(1));
               Kcr = 4*M/(pi*X);
               deterioracao=0;
               espera = espera0;
               kp = 0.6*Kcr;
               Ti = Tcr/2;
               Td = Tcr/8;
               var_aux=0;
           end
       end
   end
   espera = espera-1;
end
estrutura_de_saida = make_struct_out(x_p_out,0,0,e, ...
                                 u, r,tempo,endk);
                           

end

