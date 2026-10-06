ax = gca;
%#ok<*NOPTS>
Gp = tf([0 0 1], [1 -0.32 1])
Gs = tf([0 1 0], [1 9.04 0.36]) 
disp('PROJETO POR ROOT LOCUS')
disp('Gp é a FT da planta linearizada, usada apenas para o projeto')
disp('Gs é a FT do sensor.')
disp('aperte uma tecla para continuar')
pause

G_malha_aberta = Gp*Gs

disp('Precisamos de 2 integradores, um para cancelar o zero na origem')
disp('e mais outro para garantir erro em regime nulo versus perturbação')
disp('Raciocinio: o sistema possui dois polos complexos no semi plano direito')
disp('perto do eixo imaginário.')
disp('Desta forma podemos colocar dois zeros complexos perto do eixo imaginário') 
disp('aperte uma tecla para continuar')
pause

disp('escolhemos a seguinte FT candidata a controlador')
Gcc = tf([1 0.02+1j],[1 0])*tf([1 0.02-1j],[1 0])
disp('esperamos atrair os polos instáveis para o semi plano esquerdo, porém')
disp('aperte uma tecla para continuar')
pause

disp('ROOT LOCUS')
rlocus(Gcc*Gp*Gs)
ax.XLim(1) = -1;
ax.XLim(2) = 1;
ax.YLim(1) = -2;
ax.YLim(2) = 2;
disp('vemos que são os polos no semi plano esquerdo que são atraidos')
disp('precisamos atrair os polos instáveis!')
disp('aperte uma tecla para continuar')
pause

Gcc2 = tf([1 0.02+1j],[1 0])*tf([1 0.02-1j],[1 0])*tf([1 1],[0.1 1])
disp('colocamos um zero em -1 na FT candidata a controlador (PD)')
disp('somos obrigados a colocar um polo associado em -10(realizabilidade)')
disp('aperte uma tecla para continuar')
pause

disp('ROOT LOCUS')
rlocus(Gcc2*Gp*Gs)
ax.XLim(1) = -3;
ax.XLim(2) = 2;
ax.YLim(1) = -2.5;
ax.YLim(2) = 2.5;
disp('é possível estabilizar o sistema, porém temos outros requerimentos')
disp('notadamente, PO% impõe restrição sobre o ângulo em relação a origem')
disp('dos polos mais próximos da mesma, enquanto ts2% restringe o módulo destes')
disp('podemos tentar afastar os zeros complexos do controlador, colocando-os')
disp('em -1')
disp('aperte uma tecla para continuar')
pause

Gcc3 = tf([1 1],[1 0])*tf([1 1],[1 0])*tf([1 1],[0.1 1])
disp('escolhemos esta nova candidata')
disp('aperte uma tecla para continuar')
pause

disp('ROOT LOCUS')
rlocus(Gcc3*Gp*Gs)
ax.XLim(1) = -2;
ax.XLim(2) = 2;
ax.YLim(1) = -5;
ax.YLim(2) = 5;
disp('não conseguimos cumprir os requerimentos, o sistema se tornou instável')
disp('aperte uma tecla para continuar')
pause

Gcc4 = tf([1 1],[1 0])*tf([1 1],[1 0])*tf([1 1],[0.05 1])*tf([1 1],[0.05 1])
disp('escolhemos esta nova candidata')
disp('aperte uma tecla para continuar')
pause

disp('ROOT LOCUS')
rlocus(Gcc4*Gp*Gs)
ax.XLim(1) = -22;
ax.XLim(2) = 4;
ax.YLim(1) = -4.5;
ax.YLim(2) = 4.5;
disp('esta FT é capaz de cumprir os requerimentos e garantir estabilidade')
disp('aperte uma tecla para continuar')
pause


