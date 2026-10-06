%Lista de Comandos, Capitulo 2 da Dissertacao

[a_pal,k_pal,tempo] = L1_Paralelo_O1(30,1e-3);
[a_spal,k_spal,tempo] = L1_Serie_Paralelo_O1(30,1e-3);
[a_f,k_f,tempo] = L1_Filtragem_O1(30,1e-3);
[a_2f3,k_2f3,tempo] = L2_3M_Filtragem_O1(30,1e-3);
[a_2f4,k_2f4,tempo] = L2_4M_Filtragem_O1(30,1e-3);
[a_2f8,k_2f8,tempo] = L2_8M_Filtragem_O1(30,1e-3);
[a_2sp3,k_2sp3,tempo] = L2_3M_Serie_Paralelo_O1(30,1e-3);
SISOPLOT_O1FONLY(a_pal,a_spal,a_f,a_2f3,a_2sp3,a_2f4,a_2f8,k_pal,k_spal,k_f,k_2f3,k_2sp3,k_2f4,k_2f8,tempo)