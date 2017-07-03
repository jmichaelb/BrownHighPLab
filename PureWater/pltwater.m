function pltwater(P1,P2,P3,P4,T1,T2,T3,T4,LT,delv1,delv2,delv3,delv4,delvLT,dv1,dv2,dv3,dv4,dvLT,idp1,idp2,idp3,idp4,idpLT)


errorbar((P1(idp1)),delv1(idp1),dv1(idp1),'ko','markerfacecolor','k','Markersize',10)
hold on
errorbar((P2(idp2)),delv2(idp2),dv2(idp2),'ks','markerfacecolor','k','Markersize',10)
errorbar((P3(idp3)),delv3(idp3),dv3(idp3),'kd','markerfacecolor','k','Markersize',10)
errorbar((P4(idp4)),delv4(idp4),dv4(idp4),'k^','markerfacecolor','k','Markersize',10)

errorbar((LT(idpLT,1)),delvLT(idpLT),dvLT(idpLT),'ko','MarkerFaceColor','w','MarkerSize',10)
hold off


%ylim([-300 300])
%xlim([0 300])
txt=sprintf('Water at %i K',round(mean([T1(idp1); T2(idp2); T3(idp3); T4(idp4) ])));
title(txt)
xlabel('Pressure (MPa)')
ylabel('Deviations from IAPWS (ppm)')