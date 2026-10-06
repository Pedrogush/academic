
function x_p = calc_x_p(t,x,u)
x_p = [-1 1; 0 -1]*x + [0; 1]*u;
end