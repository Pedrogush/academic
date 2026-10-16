"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/make_struct.m

Packs the outputs of the toolbox simulations (L1A, L2AA, L2AA_CL, ...) in a struct whose
field names are the argument names (the MATLAB version calls
``convert_names_to_fields``, which uses ``inputname``).

Porting notes:
- ``convert_names_to_fields`` is not in this folder (it lives in
  classwork/graduate/2016-1-adaptive-control/code/Identificação/); since ``inputname``
  has no Python equivalent the field names are written out explicitly here. They are the
  names used by every caller in this folder.
- Returns a ``Struct`` (dict with attribute access, see convert_struct.py).
"""
from convert_struct import Struct


def make_struct(x_p, x_m, eta, theta_p_estimativa, norm_2_e_o,
                e_o, u, alfa_barra, r, modelo_de_referencia,
                planta, theta_BARRA, modelos, tempo, endk):
    estrutura = Struct(x_p=x_p, x_m=x_m, eta=eta,
                       theta_p_estimativa=theta_p_estimativa,
                       norm_2_e_o=norm_2_e_o, e_o=e_o, u=u, alfa_barra=alfa_barra,
                       r=r, modelo_de_referencia=modelo_de_referencia, planta=planta,
                       theta_BARRA=theta_BARRA, modelos=modelos, tempo=tempo, endk=endk)
    return estrutura
