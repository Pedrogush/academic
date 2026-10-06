
function  gamma_0 = calc_gamma_0(K, ref, tau_dom,tau_men, theta_estrela)
for i=1:length(theta_estrela)
    number = (log10(K)-log10(tau_dom)-2*log(ref)+log10(theta_estrela(i))-sat0(i-3)*log10(tau_men));
    gamma_0(i) = 10^(floor(number));
end
end