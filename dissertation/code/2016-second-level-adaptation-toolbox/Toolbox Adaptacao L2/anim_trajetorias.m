function video_trajetoria = anim_trajetorias(func,args)
estrutura = func(args);
%ANIM_TRAJETORIAS Summary of this function goes here
%   Detailed explanation goes here
tic
    theta0 = estrutura.theta_BARRA(:,:,1)*estrutura.alfa_barra(:,1);
    aniline = animatedline('MaximumNumPoints',4,'LineWidth',3.0,'Color',[0.35 0.5 0]);
    a11(estrutura.endk) = 0;
    a21(estrutura.endk) = 0;
    a12(estrutura.endk) = 0;
    a22(estrutura.endk) = 0;
    a13(estrutura.endk) = 0;
    a23(estrutura.endk) = 0;
         video_trajetoria = VideoWriter('testavi.avi');
    for k=1:estrutura.endk
        fig1 = figure(1);
  
    a11(k) = estrutura.theta_BARRA(1,1,k);
    a21(k) = estrutura.theta_BARRA(2,1,k);
    a12(k) = estrutura.theta_BARRA(1,2,k);
    a22(k) = estrutura.theta_BARRA(2,2,k);
    a13(k) = estrutura.theta_BARRA(1,3,k);
    a23(k) = estrutura.theta_BARRA(2,3,k);
    skip = args.stoptime/(args.nframes*args.h);
        if length(args.planta)==2 && floor(k/skip)==ceil(k/skip)
        addpoints(aniline,[estrutura.theta_BARRA(1,:,k) estrutura.theta_BARRA(1,1,k)],[estrutura.theta_BARRA(2,:,k) estrutura.theta_BARRA(2,1,k)])
            if k>4
            km1=(k-1):-1:(k-1);
            km2=(k-1):-1:1;
            else
            km1=1;
            km2=1;
            end
        line([a11(k) a11(km2)], [a21(k) a21(km2)], 'Color', [1-args.cor args.cor 1-args.cor],'LineWidth',0.6);
        line([a12(k) a12(km2)], [a22(k) a22(km2)], 'Color', [1-args.cor args.cor 1-args.cor],'LineWidth',0.6);
        line([a13(k) a13(km2)], [a23(k) a23(km2)], 'Color', [1-args.cor args.cor 1-args.cor],'LineWidth',0.6);
        video_trajetoria = addframe(video_trajetoria, fig1);
        hold on, grid on
        s = line(args.planta(1), args.planta(2),'Color',[args.cor 1-args.cor 1-args.cor], 'LineWidth', 1.0);
        line([theta0(1) args.planta(1)],[theta0(2) args.planta(2)]);
        s.Marker = 'o';
        line([args.modelos(1,:) args.modelos(1,1)],[args.modelos(2,:) args.modelos(2,1)], 'Color', [1-args.cor args.cor args.cor],'LineWidth',1.0);
        line([estrutura.theta_p_estimativa(1,k) estrutura.theta_p_estimativa(1,km2)], [estrutura.theta_p_estimativa(2,k) estrutura.theta_p_estimativa(2,km2)], 'Color', [args.cor args.cor 1-args.cor],'LineWidth',1.0);
        end
    end
    toc
end

