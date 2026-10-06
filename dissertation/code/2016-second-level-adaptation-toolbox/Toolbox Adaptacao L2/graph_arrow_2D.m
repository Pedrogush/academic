function graph_arrow_2D( thetak, thetak_mais_1 )
%ARROW Summary of this function goes here
%   Detailed explanation goes here
ax = gca;

vetor   = thetak-thetak_mais_1;
tamanho = norm(vetor)/70;

p1_seta = thetak;
p2_seta = thetak + 0.01*vetor*[cos(225/180*pi) -sin(225/180*pi); sin(225/180*pi) cos(225/180*pi)];
p3_seta = thetak + 0.01*vetor*[cos(-225/180*pi) -sin(-225/180*pi); sin(-225/180*pi) cos(-225/180*pi)];
fill([p1_seta(1) p2_seta(1) p3_seta(1) p1_seta(1)], [p1_seta(2) p2_seta(2) p3_seta(2) p1_seta(2)], [0 0 0]);

line([thetak(1) thetak_mais_1(1)], [thetak(2) thetak_mais_1(2)],'LineWidth',2, 'Color', [0 0 0])

end

