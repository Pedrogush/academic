
function tau_men_seg_ordem = calc_tau_men_seg_ordem(theta_estrela_seg_ordem)
tau_men_seg_ordem = -real(-theta_estrela_seg_ordem(3)-sqrt(theta_estrela_seg_ordem(3)^2-4*theta_estrela_seg_ordem(4)))/2;
end