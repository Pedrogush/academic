 function phase()
 IC = 5*(rand(200,2)-0.5);
 hold on
 for ii = 1:length(IC(:,1))
    [~,X] = ode45(@EOM,[-5 5],IC(ii,:));
    u = X(:,1);
    w = X(:,2);
    plot(u,w,'r')
 end
 xlabel('u')
 ylabel('w')
 grid
 x       = -4:0.5:4;
 y       = -4:0.5:4;
 [xg,yg] = meshgrid(x,y);
 dxg     = yg.*xg.^2 - xg;
 dyg     = ones(length(x)) - yg - yg.*xg.^2;
 scale   = 5;
 quiver(xg,yg,dxg,dyg,scale)
 end

function dX = EOM(t, y)
 dX = [2;1];
 u  = y(1);
 w  = y(2);
 A  = 1;
 B  = 1;
 dX = [(w*u^2 - B*u);...
      (A - w - w*u^2)];
 end