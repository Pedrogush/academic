function passo_exponencial = pass_exp(t, tadpt, contador_laco)
    passo_exponencial=1.05;
if tadpt<=400*t
    passo_exponencial = 1.02;
end
if tadpt<=40*t
    passo_exponencial = 1.01;
end
if tadpt<=4*t
    passo_exponencial = 1.001;
end
if contador_laco>=3
    passo_exponencial = rand();
end
end