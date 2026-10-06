function estrutura = make_struct_out_MRAC(x_p_out,x_m_out,theta,e_o, ...
                                 u, r,tempo,endk)
estrutura.x_p_out = x_p_out; estrutura.x_m_out=x_m_out; 
estrutura.theta(:,:) = theta(:,1,:); 
estrutura.e_o=e_o;estrutura.u=u;
estrutura.tempo=tempo; estrutura.r=r; estrutura.endk = endk; 
end