function tabbedGUI()
    %# create tabbed GUI
    hFig = figure('Menubar','none');
    s = warning('off', 'MATLAB:uitabgroup:OldVersion');
    hTabGroup = uitabgroup('Parent',hFig);
    warning(s);
    Sim_Par = struct('t_0', NaN,'t_final', NaN,'h',NaN, 'modelos',NaN, ...
   'planta',NaN, 'modelo_ref',NaN, 'cond_iniciais_p',NaN,'cond_iniciais_m'...
   ,NaN,'cond_iniciais_i',NaN, 'alfa_0',NaN,'Q',NaN,'gamma',NaN,'P',NaN,  ...
   'not_used',NaN,'ref_amp',NaN,'ref_freq',NaN,'tol_eta',NaN,'tau_ref',NaN);
    Current_Simulation_Output = struct('x_p',NaN,'x_m',NaN,'eta',NaN,      ...
   'theta_p_estimativa',NaN,'norm_2_e_o',NaN,'e_o',NaN,'u',NaN,'alfa_barra'...
   ,NaN, 'r',NaN, 'modelo_de_referencia',NaN,'planta',NaN, 'theta_BARRA',  ...
    NaN, 'modelos',NaN,'tempo',NaN,'endk',NaN);

    hTabs(1) = uitab('Parent',hTabGroup, 'Title',                          ...
                'Parametros de Simulação');
    hTabs(2) = uitab('Parent',hTabGroup, 'Title',                          ...
                'Plotagem de Trajetória no Espaço de Parâmetros da Planta');
    hTabs(3) = uitab('Parent',hTabGroup, 'Title',                          ...
                'Plotagem dos Sinais de Controle');
    hTabs(4) = uitab('Parent',hTabGroup, 'Title',                          ...
                'Plotagem dos Sinais de Identificação');
    hTabs(5) = uitab('Parent',hTabGroup, 'Title',                          ...
                'Diagrama de Simulação');
    hTabs(6) = uitab('Parent',hTabGroup, 'Title',                          ...
                'Opções');
    hTabs(7) = uitab('Parent',hTabGroup, 'Title',                          ...
                'Animações');
    set(hTabGroup, 'SelectedTab',hTabs(1));

    %# populate tabs with UI components
    
    %Componentes de UI na aba 1
h_txt = uicontrol('Parent', hTabs(1), 'Style', 'text', 'String', 'Passo de Integração', ...
      'HorizontalAlignment', 'left', 'Position', [80 600 450 25]) ;
h_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 600 150 30],'Callback',@h_callback) ;
    
t_0_txt = uicontrol('Parent', hTabs(1), 'Style', 'text', 'String', 'Tempo Inicial', ...
      'HorizontalAlignment', 'left', 'Position', [80 540 140 25]) ;
t_0_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 540 200 30],'Callback',@t_0_callback) ;

t_final_txt = uicontrol('Parent', hTabs(1), 'Style', 'text', 'String', 'Tempo Final', ...
      'HorizontalAlignment', 'left', 'Position', [80 480 170 25]) ;
t_final_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 480 200 30],'Callback',@t_final_callback) ;

modelos_txt = uicontrol('Parent', hTabs(1), 'Style', 'text', 'String', 'Modelos de Identificação', ...
      'HorizontalAlignment', 'left', 'Position', [80 420 170 25]) ;
modelos_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 420 200 30],'Callback',@modelos_callback) ;

planta_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Modelo da Planta','HorizontalAlignment', 'left', 'Position',...
      [80 360 170 25]) ;
planta_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 360 200 30],'Callback',@planta_callback) ;

modelo_ref_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Modelo de Referência','HorizontalAlignment', 'left', 'Position',...
      [80 300 170 25]) ;
modelo_ref_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 300 200 30],'Callback',@modelo_ref_callback) ;


cond_iniciais_p_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Condições Iniciais da Planta','HorizontalAlignment', 'left', 'Position',...
      [80 240 170 25]) ;
cond_iniciais_p_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 240 200 30],'Callback',@cond_iniciais_p_callback) ;
    
cond_iniciais_m_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Condições Iniciais do Modelo de Referência','HorizontalAlignment', 'left', 'Position',...
      [80 180 170 25]) ;
cond_iniciais_m_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 180 200 30],'Callback',@cond_iniciais_m_callback) ;

cond_iniciais_i_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Condições Iniciais dos Modelos De Identificação','HorizontalAlignment', 'left', 'Position',...
      [80 120 170 30]) ;
cond_iniciais_i_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 120 150 30],'Callback',@cond_iniciais_i_callback);

alfa_0_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Alfa 0, Estimativa Inicial do Modelo Virtual','HorizontalAlignment', 'left', 'Position',...
      [80 60 170 30]) ;
alfa_0_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [270 60 150 30],'Callback',@alfa_0_callback);

Q_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Matriz Q de Avaliação da Taxa de Adaptação','HorizontalAlignment', 'left', 'Position',...
      [600 600 170 30]) ;
Q_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [790 600 150 30],'Callback',@Q_callback);

gamma_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Ganho adaptativo do Modelo Virtual','HorizontalAlignment', 'left', 'Position',...
      [600 540 170 30]) ;
gamma_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [790 540 150 30],'Callback',@gamma_callback);

P_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Matriz de Ganhos Adaptativos dos Modelos de Identificação','HorizontalAlignment', 'left', 'Position',...
      [600 480 170 30]) ;
P_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [790 480 150 30],'Callback',@P_callback);

ref_amp_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Vetor de Amplitudes das Senóides de Referência','HorizontalAlignment', 'left', 'Position',...
      [600 420 170 30]) ;
ref_amp_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [790 420 150 30],'Callback',@ref_amp_callback);

ref_freq_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Vetor de Frequências das Senóides de Referência','HorizontalAlignment', 'left', 'Position',...
      [600 360 170 30]) ;
ref_freq_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [790 360 150 30],'Callback',@ref_freq_callback);


tol_eta_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Tolerância de Desligamento da parcela PE do Sinal de Referência','HorizontalAlignment', 'left', 'Position',...
      [600 300 170 30]) ;
tol_eta_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [790 300 150 30],'Callback',@tol_eta_callback);

tau_ref_txt = uicontrol('Parent', hTabs(1), 'Style', 'text',    ...
      'String', 'Constante de Tempo de Retorno à Referência Constante','HorizontalAlignment', 'left', 'Position',...
      [600 240 170 30]) ;
tau_ref_edt = uicontrol('Parent', hTabs(1), 'Style', 'edit', ...
 'Position', [790 240 150 30],'Callback',@tau_ref_callback);

 btn_save = uicontrol('Parent',hTabs(1),'Style', 'pushbutton', 'String', 'Save Simulation Parameters',...
        'Position', [790 180 150 30],'Callback',@SaveButtonCallback);       
 btn_load = uicontrol('Parent',hTabs(1),'Style', 'pushbutton', 'String', 'Load Simulation Parameters',...
        'Position', [790 150 150 30],'Callback',@LoadButtonCallback);       
 btn_simulate = uicontrol('Parent',hTabs(1),'Style', 'pushbutton', 'String', 'Run Simulation',...
        'Position', [790 120 150 30],'Callback',{@RunSimulationCallback});       


Tipo_de_Sim_txt = uicontrol('Parent', hTabs(6), 'Style', 'text',    ...
      'String', 'Tipo de Simulação','HorizontalAlignment', 'left', 'Position',...
      [80 600 450 25]) ;
Tipo_de_Sim_edt = uicontrol('Parent', hTabs(6), 'Style', 'popupmenu', ...
 'Position', [270 600 450 30], 'String', ...
 {'Identificação de Parâmetros de uma Planta Conhecida com Incertezas' ...
  'Identificação e Controle de uma Planta Conhecida com Incertezas'    
  });


Tipo_de_ident_txt = uicontrol('Parent', hTabs(6), 'Style', 'text',    ...
      'String', 'Método de Identificação','HorizontalAlignment', 'left', 'Position',...
      [80 540 450 25]) ;
Tipo_de_ident_edt = uicontrol('Parent', hTabs(6), 'Style', 'popupmenu', ...
 'Position', [270 540 450 30], 'String', ...
 {'Adaptação de Segundo Nível' ...
  'Método do Gradiente com Função de Custo Integral'});

Tipo_de_acesso_txt = uicontrol('Parent', hTabs(6), 'Style', 'text',    ...
      'String', 'Medidas Disponíveis da Planta','HorizontalAlignment', 'left', 'Position',...
      [80 480 450 25]) ;
Tipo_de_acesso_edt = uicontrol('Parent', hTabs(6), 'Style', 'popupmenu', ...
 'Position', [270 480 450 30], 'String', ...
 {'Vetor de Estados da Planta Acessível, Planta Sem Zeros' ...
  'Caso SISO'});

Lang_txt = uicontrol('Parent', hTabs(6), 'Style', 'text',    ...
      'String', 'Línguagem','HorizontalAlignment', 'left', 'Position',...
      [80 420 450 25]) ;
Lang_edt = uicontrol('Parent', hTabs(6), 'Style', 'popupmenu', ...
 'Position', [270 420 450 30], 'String', ...
 {'Português' ...
  'Inglês'});

%stoptime*, h*, modelos*, planta*, modelo_de_referencia*, cond_iniciais_p*,   ...
% cond_iniciais_m*,cond_iniciais_i*, alfa0*,Q*,gamma*,P*,~,ref_amp*, ...
% ref_freq*,tol_eta,tau_ref

%plots de controle
    hAx = axes('Parent',hTabs(3));
    subplot(4,2,[1 3])
    plot(NaN, NaN, 'Color','r');
    subplot(4,2,[2 4])
    plot([1 1], [2 2]);
    subplot(4,2,[5 7])
    plot([1 1], [2 2]);
    subplot(4,2,[6 8])
    plot([1 1], [2 2]);
    %plots de identificação    
    
    hAx = axes('Parent',hTabs(4));
    subplot(4,2,[1 3])
    plot(NaN, NaN, 'Color','r');
    subplot(4,2,[2 4])
    plot([1 1], [2 2]);
    subplot(4,2,[5 7])
    plot([1 1], [2 2]);
    subplot(4,2,[6 8])
    plot([1 1], [2 2]);
    
    %plots de trajetória
     hAx = axes('Parent',hTabs(2));
    subplot(4,2,[1 3])
    plot(NaN, NaN, 'Color','r');
    subplot(4,2,[2 4])
    plot([1 1], [2 2]);
    subplot(4,2,[5 7])
    plot([1 1], [2 2]);
    subplot(4,2,[6 8])
    plot([1 1], [2 2]);  
    
    
    hAx7 = axes('Parent',hTabs(7));
    plot([1 1], [2 2]);
    
    hAx5 = axes('Parent',hTabs(5));
    plot([0 0], [0 0]);

    
%tab 1 callback functions group
function h_callback(src,evt)
        Sim_Par.h = str2num(src.String)
end
function t_0_callback(src,evt)
        Sim_Par.t_0 = str2num(src.String);
end

function t_final_callback(src,evt)
        Sim_Par.t_final = str2num(src.String);
end

function modelos_callback(src,evt)
        Sim_Par.modelos= str2num(src.String);
end
function planta_callback(src,evt)
        Sim_Par.planta = str2num(src.String);
end
function modelo_ref_callback(src,evt)
        Sim_Par.modelo_ref = str2num(src.String);
end
function cond_iniciais_p_callback(src,evt)
        Sim_Par.cond_iniciais_p = str2num(src.String);
end
function cond_iniciais_m_callback(src,evt)
        Sim_Par.cond_iniciais_m = str2num(src.String);
end
function cond_iniciais_i_callback(src,evt)
        Sim_Par.cond_iniciais_i = str2num(src.String);
end
function alfa_0_callback(src,evt)
        Sim_Par.alfa_0 = str2num(src.String);
end
function Q_callback(src,evt)
        Sim_Par.Q = str2num(src.String);
end

function gamma_callback(src,evt)
        Sim_Par.gamma = str2num(src.String);
end

function P_callback(src,evt)
        Sim_Par.P = str2num(src.String);
end
function ref_amp_callback(src,evt)
        Sim_Par.ref_amp = str2num(src.String);
end
function ref_freq_callback(src,evt)
        Sim_Par.ref_freq = str2num(src.String);
end
function tol_eta_callback(src,evt)
        Sim_Par.tol_eta = str2num(src.String);
end
function tau_ref_callback(src,evt)
        Sim_Par.tau_ref = str2num(src.String);
end

    function SaveButtonCallback(src,evt)
        Parameters = Sim_Par;
        uisave('Parameters')
    end


    %# button callback

function LoadButtonCallback(src,evt)
        %# load data
        [fName,pName] = uigetfile('*.mat', 'Load data');
        if pName == 0, return; end
        load(fullfile(pName,fName), '-mat', 'Parameters');
        Sim_Par = Parameters;
        Update_Parameter_Fields(Parameters) 
    end
    
    function Update_Parameter_Fields(Parameters)
        
    h_edt.String = mat2str(Parameters.h);
    modelos_edt.String = mat2str(Parameters.modelos);    
    planta_edt.String = mat2str(Parameters.planta);    
    t_0_edt.String = mat2str(Parameters.t_0);    
    t_final_edt.String = mat2str(Parameters.t_final);    
    modelo_ref_edt.String = mat2str(Parameters.modelo_ref);    
    cond_iniciais_p_edt.String = mat2str(Parameters.cond_iniciais_p);    
    cond_iniciais_i_edt.String = mat2str(Parameters.cond_iniciais_i);    
    cond_iniciais_m_edt.String = mat2str(Parameters.cond_iniciais_m);    
    alfa_0_edt.String = mat2str(Parameters.alfa_0);    
    Q_edt.String = mat2str(Parameters.Q);
    gamma_edt.String = mat2str(Parameters.gamma);    
    P_edt.String = mat2str(Parameters.P);
    ref_amp_edt.String = mat2str(Parameters.ref_amp);
    ref_freq_edt.String = mat2str(Parameters.ref_freq);
    tol_eta_edt.String = mat2str(Parameters.tol_eta);
    tau_ref_edt.String = mat2str(Parameters.tau_ref);

    end


%stoptime*, h*, modelos*, planta*, modelo_de_referencia*, cond_iniciais_p*,   ...
% cond_iniciais_m*,cond_iniciais_i*, alfa0*,Q*,gamma*,P*,~,ref_amp*, ...
% ref_freq*,tol_eta,tau_ref


function RunSimulationCallback(src,evt)
sw_1 = Tipo_de_Sim_edt.Value;
%'Identificação de Parâmetros de uma Planta Conhecida com Incertezas' ...
%'Identificação e Controle de uma Planta Conhecida com Incertezas'   
sw_2 = Tipo_de_ident_edt.Value;
%'Adaptação de Segundo Nível' ...
%  'Método do Gradiente com Função de Custo Integral'
sw_3 = Tipo_de_acesso_edt.Value;
%'Vetor de Estados da Planta Acessível, Planta Sem Zeros' ...
%  'Caso SISO'

switch [sw_1,sw_2,sw_3]
    case [1,1,1]
        Current_Simulation_Output = L2AA_Ident(Sim_Par); %DONE
    case [1,1,2]
        Current_Simulation_Output = L2A_IO_Ident(Sim_Par); %Zeros
    case [1,2,1]
        Current_Simulation_Output = Gradiente_FCI_VE(Sim_Par); %?
    case [1,2,2]
        Current_Simulation_Output = Gradiente_FCI(Sim_Par); %DONE
    case [2,1,1]
        Current_Simulation_Output = L2AA(Sim_Par); %DONE
    case [2,1,2]
        Current_Simulation_Output = L2A_IO(Sim_Par); %Zeros
    case [2,2,1]
        Current_Simulation_Output = APPC_VE(Sim_Par);%?
    case [2,2,2]
        Current_Simulation_Output = APPC(Sim_Par);%DONE
end


end

end