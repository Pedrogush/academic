function [redvec1,redvec2] = VectorReduction(vec1,vec2,eucl_dist_min,axis1min,axis1max,axis2min,axis2max)
%entrada principal: o par de vetores vec1 e vec2
%saída:posições em que um marcador deve ser plotado no gráfico, na forma
%dos vetores redvec1 e redvec2
%parametros: eucl_dist_min distância euclidiana minima entre marcadores
%            axis1min,axis1max,axis2min,axis2max -> os limites dos eixos do gráfico
size = length(vec1);
i=1;
scale = abs(axis1min-axis1max)/abs(axis2min-axis2max);
redvec1(1)=vec1(1);
redvec2(1)=vec2(1);
for k=1:size   
   eucl_dist = sqrt((vec1(k)-redvec1(i))^2+scale^2*(vec2(k)-redvec2(i))^2);
    if eucl_dist>eucl_dist_min
   %if abs(vec1(k)-redvec1(i))>eucl_dist_min || scale*abs(vec2(k)-redvec2(i))>eucl_dist_min
    i=i+1;
    redvec1(i)=vec1(k);
    redvec2(i)=vec2(k);
    end
end
end