"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/make_struct_out.m

Packs the identifier outputs (teta, time x, z1, z1e, eo, plant output, m, u)
into a struct with those field names, for plot_adap_figures_Ident /
plot_adap_figures_APPC.

Porting notes:
- Struct = dict; field names given explicitly (MATLAB used inputname inside
  convert_names_to_fields, which yields exactly these parameter names).
"""
from convert_names_to_fields import convert_names_to_fields


def make_struct_out(teta, x, z1, z1e, eo, saida_planta, m, u):
    estrutura = convert_names_to_fields(
        teta, x, z1, z1e, eo, saida_planta, m, u,
        names=["teta", "x", "z1", "z1e", "eo", "saida_planta", "m", "u"])
    return estrutura
