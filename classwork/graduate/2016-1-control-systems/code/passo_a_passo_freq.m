ax = gca;
%#ok<*NOPTS>
Gp = tf([0 0 1], [1 -0.32 1])
Gs = tf([0 1 0], [1 9.04 0.36]) 
disp('PROJETO POR ROOT LOCUS')
disp('Gp é a FT da planta linearizada, usada apenas para o projeto')
disp('Gs é a FT do sensor.')
disp('aperte uma tecla para continuar')
pause


Gcc3 = tf([1 0.7],[1 0])*tf([1 0.7],[1 0])*tf([1 0.7],[0.1 1])
disp('Partimos do passo 3 para o projeto em frequência, pois sabemos que')
disp('necessitamos de um sistema estável para este tipo de projeto')
disp('aperte uma tecla para continuar')
pause

disp('ROOT LOCUS')
rlocus(Gcc3*Gp*Gs)
ax.XLim(1) = -2;
ax.XLim(2) = 2;
ax.YLim(1) = -5;
ax.YLim(2) = 5;
disp('fazemos apenas o suficiente para atrair os polos da malha interna')
disp('para dentro do semi plano esquerdo, escolhendo kp=18')
disp('aperte uma tecla para continuar')
pause

Gcc3 = tf(18*[1 2.1 1.47 0.343], [0.1 1 0 0]);
Gma = feedback(Gcc3*Gp*Gs,1)
disp('função de transferência do sistema estabilizado')
disp('aperte uma tecla para continuar')
pause

disp('DIAGRAMA DE BODE')
margin(Gma)
disp('vemos que a margem de fase e largura de banda estão abaixo das especificações')
disp('projetamos um controlador avanço para compensar')
disp('aperte uma tecla para continuar')
pause

Gcf = tf(0.3*[1 1],[0.05 1])
disp('com isso, deslocamos a frequência de cruzamento para a direita')
disp('e melhoramos a margem de fase')
disp('aperte uma tecla para continuar')
pause

disp('DIAGRAMA DE BODE DO CONTROLADOR')
bode(Gcf)
disp('aperte uma tecla para continuar')
pause

disp('DIAGRAMA DE BODE DO CONTROLADOR + PLANTA')
margin(Gcf*Gma)
disp('aperte uma tecla para continuar')
pause