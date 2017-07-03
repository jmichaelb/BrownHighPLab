% water data

load('UW_H2O.mat')


% put data into matrixes organized by load 

np4=length(UW_H2O_4);
np1=length(UW_H2O_1);
np2=length(UW_H2O_2);
np3=length(UW_H2O_3);

data4=zeros(np4,9);
data1=zeros(np1,9);
data2=zeros(np2,9);
data3=zeros(np3,9);
%


for i=1:np1
    data1(i,:)=[UW_H2O_1(i).O1 UW_H2O_1(i).O2 UW_H2O_1(i).O1zero  UW_H2O_1(i).H1 273.15+UW_H2O_1(i).C2 0 UW_H2O_1(i).TWTT UW_H2O_1(i).length UW_H2O_1(i).TWTTrms];
end
for i=1:np2
    data2(i,:)=[UW_H2O_2(i).O1 UW_H2O_2(i).O2 UW_H2O_2(i).O1zero  UW_H2O_2(i).H1 273.15+UW_H2O_2(i).C2 0 UW_H2O_2(i).TWTT UW_H2O_2(i).length UW_H2O_2(i).TWTTrms];
end
for i=1:np3
    data3(i,:)=[UW_H2O_3(i).O1 UW_H2O_3(i).O2 UW_H2O_3(i).O1zero  UW_H2O_3(i).H1 273.15+UW_H2O_3(i).C2 0 UW_H2O_3(i).TWTT UW_H2O_3(i).length UW_H2O_3(i).TWTTrms];
end

for i=1:np4
    data4(i,:)=[UW_H2O_4(i).O1 UW_H2O_4(i).O2 UW_H2O_4(i).O2zero  UW_H2O_4(i).H1 273.15+UW_H2O_4(i).C2 data(i).RoomT UW_H2O_4(i).TWTT UW_H2O_4(i).length UW_H2O_4(i).TWTTrms];
end
%
data1=data1([1:42 45:np1],:);  %remove two clearly bad points taken sequentially
np1=np1-2;

%
% the micrometer measurement of the sample chamber length (294 K) is 10769 microns +/- 1 micron
% the following are the lengths needed to match IAPWS at 1 bar and 40°C
% during 4 different runs over 2 years. 10770 has been the "default" length
% in code

fac4=10768.7;
fac3=10767.5;
fac2=10767.5;
fac1=10769;


vel1=2*fac1/10770*data1(:,8)./data1(:,7);
vel2=2*fac2/10770*data2(:,8)./data2(:,7);
vel3=2*fac3/10770*data3(:,8)./data3(:,7);
vel4=2*fac4/10770*data4(:,8)./data4(:,7);

dv1=1e6*data1(:,9)./data1(:,7);
dv2=1e6*data2(:,9)./data2(:,7);
dv3=1e6*data3(:,9)./data3(:,7);
dv4=1e6*data4(:,9)./data4(:,7);

%set 100 ppm as the miniumum allowed uncertainty
dv1(dv1<100)=100;
dv2(dv2<100)=100;
dv3(dv3<100)=100;
dv4(dv4<100)=100;

T1=data1(:,5);
T2=data2(:,5);
T3=data3(:,5);
T4=data4(:,5);
P1=data1(:,1);
P2=data2(:,1);
P3=data3(:,1);
P4=data4(:,1);


id1=find(data1(:,3)==.1);
id2=find(data2(:,3)==.1);
id3=find(data3(:,3)==.1);
id4=find(data4(:,3)==.1);

% where 1 bar readings for Omega 1 were not recodered, use a "normal" value of -0.6 MPa
% since the default was set to +.1 MPa need to add 0.5 to correct: 
P1(id1)=P1(id1)+.5;
P2(id2)=P2(id2)+.5;
P3(id3)=P3(id3)+.5;
P4(id4)=P4(id4)+.5;

% this "corrects" Omega 1 and Heise 1 to pressures as given by Omega 2
[P1,P1H]=P_cor(P1,data1(:,4));
[P2,P2H]=P_cor(P2,data2(:,4));
[P3,P3H]=P_cor(P3,data3(:,4));
[P4,P4H]=P_cor(P4,data4(:,4));
P1(isnan(P1))=.1;
P2(isnan(P2))=.1;
P3(isnan(P3))=.1;
P4(isnan(P4))=.1;


% get the Lin and Trusler data:
LT=LT_data;
% the following is a "correction" as noted in June 2017 to make L&T agree
% with our data
pfac=.007;
LT(:,1)=LT(:,1).*(1+pfac*LT(:,1)/700);


% get IAPWS predictions for all data
iapws1=IAPWS95([P1(:) T1(:)],'P');
iapws2=IAPWS95([P2(:) T2(:)],'P');
iapws3=IAPWS95([P3(:) T3(:)],'P');
iapws4=IAPWS95([P4(:) T4(:)],'P');
iapwsLT=IAPWS95([LT(:,1) LT(:,2)],'P');


% following is a method to select some data for plotting:
id1=find(data1(:,1)>0);
id2=find(data2(:,1)>0);
id3=find(data3(:,1)>0);
id4=find(data4(:,1)>0);

% calculate (Exp-IAPWS)/Exp in ppm
delv1=1e6*(vel1-iapws1.vel)./vel1;
delv2=1e6*(vel2-iapws2.vel)./vel2;
delv3=1e6*(vel3-iapws3.vel)./vel3;
delv4=1e6*(vel4-iapws4.vel)./vel4;
delvLT=1e6*(LT(:,3)-iapwsLT.vel)./LT(:,3);
dvLT=1e6*LT(:,4)./LT(:,3);

%%
% fit a surface to the deviations:
idLT=find(LT(:,2)>370);
PTh={.1:10:500,250};
nph=length(PTh{1});
results=holten_LT_EOS(PTh);
iapwsh=IAPWS95(PTh,'P');
delvH=1e6*(results.vel-iapwsh.vel)./results.vel;

fict=[700 500 0 1; 1000 500 -1000 1;75 263 -2400 1];
PT2fit=[[P1;P2;P3;P4;LT(idLT,1)] [T1;T2;T3;T4;LT(idLT,2)]];
PT2fit=[PT2fit;fict(:,1:2)];

devs2fit=[delv1;delv2;delv3;delv4;delvLT(idLT)];
devs2fit=[devs2fit;fict(:,3)];

devuncert2fit=.1*[dv1;dv2;dv3;dv4;dvLT(idLT)];
devuncert2fit=[devuncert2fit;fict(:,4)];

Pg=0:5:1000;
Tg=[240:5:280 300:20:500];
%Tg=[240:10:500];

PTc={Pg,Tg};
options.Xc=PTc;
options.lam=2*[100 10];

spH2Odevs=spdft(PT2fit,devs2fit,devuncert2fit,options);


%
figure(11)
subplot(211)
msz=8;
plot3((P4),T4,delv4,'k^','MarkerFaceColor','k','MarkerSize',msz)
hold on
plot3((P1(id1)),T1(id1),delv1(id1),'ko','MarkerFaceColor','k','MarkerSize',msz)
plot3((P2(id2)),T2(id2),delv2(id2),'ks','MarkerFaceColor','k','MarkerSize',msz)
plot3((P3(id3)),T3(id3),delv3(id3),'kd','MarkerFaceColor','k','MarkerSize',msz)
hold on
plot3(LT(:,1),LT(:,2),delvLT,'ro','MarkerFaceColor','r','MarkerSize',5)
plot3(PTh{1},ones(nph,1)*PTh{2},delvH,'kp','MarkerFaceColor','k','MarkerSize',10)
%zlim([-10e3 4e3])
ylim([240 500])
xlim([-0 1000])
view([90 0])
fnplt(spH2Odevs)
hold off


subplot(212)
plot3(PT2fit(:,1),PT2fit(:,2),spH2Odevs.Data.devs,'ko','MarkerFaceColor','k')

%%
Pg=0:5:1000;
Tg=[240:5:280 300:20:500];
%Tg=[240:10:500];
PTc={Pg,Tg};
%fict=[700 500 0 1; 1000 500 -1000 1;75 263 -2400 1];
PT2fit=[[P1;P2;P3;P4;LT(idLT,1)] [T1;T2;T3;T4;LT(idLT,2)]];
%PT2fit=[PT2fit;fict(:,1:2)];


%fit velocities rather than deviations from IAPWS95
vels2fit=[vel1;vel2;vel3;vel4;LT(idLT,3)];
dvs2fit= 1e-6*[dv1;dv2;dv3;dv4;.5*dvLT(idLT)].*vels2fit;

options.Xc=PTc;
options.lam=1*[10 10];

spH2Ovels=spdft(PT2fit,vels2fit,dvs2fit,options);

figure(12)
subplot(211)
msz=8;
plot3((P4),T4,vel4,'k^','MarkerFaceColor','k','MarkerSize',msz)
hold on
plot3((P1(id1)),T1(id1),vel1(id1),'ko','MarkerFaceColor','k','MarkerSize',msz)
plot3((P2(id2)),T2(id2),vel2(id2),'ks','MarkerFaceColor','k','MarkerSize',msz)
plot3((P3(id3)),T3(id3),vel3(id3),'kd','MarkerFaceColor','k','MarkerSize',msz)
hold on
plot3(LT(:,1),LT(:,2),LT(:,3),'ro','MarkerFaceColor','r','MarkerSize',5)
%plot3(PTh{1},ones(nph,1)*PTh{2},delvH,'kp','MarkerFaceColor','k','MarkerSize',10)
%zlim([-10e3 4e3])
ylim([240 500])
xlim([-0 1000])
view([90 0])
fnplt(spH2Ovels)
hold off

subplot(212)
plot3(PT2fit(:,1),PT2fit(:,2),1e6*spH2Ovels.Data.devs./vels2fit,'ko','MarkerFaceColor','k')

%
figure(13)
subplot(211)
fnplt(fnder(spH2Ovels,[2 0]));
subplot(212)
fnplt(fnder(spH2Ovels,[0 2]));

%%

% make separate plots of  deviations for various temperature ranges.\

% method to remove lower quality data:
msftcut=400;

idp11=find(T1>350 & T1<380 & dv1<msftcut);
idp21=find(T2>350 & T2<380 & dv2<msftcut);
idp31=find(T3>350 & T3<380 & dv3<msftcut);
idp41=find(T4>350 & T4<380 & dv4<msftcut);
idpLT1=find(LT(:,2)>350 & LT(:,2)<380 );

idp12=find(T1>320 & T1<330 & dv1<msftcut);
idp22=find(T2>320 & T2<330 & dv2<msftcut);
idp32=find(T3>320 & T3<330 & dv3<msftcut);
idp42=find(T4>320 & T4<330 & dv4<msftcut);
idpLT2=find(LT(:,2)>320 & LT(:,2)<330 );

idp13=find(T1>330 & T1<340 & dv1<msftcut);
idp23=find(T2>330 & T2<340 & dv2<msftcut);
idp33=find(T3>330 & T3<340 & dv3<msftcut);
idp43=find(T4>330 & T4<340 & dv4<msftcut);
idpLT3=find(LT(:,2)>330 & LT(:,2)<340 );
% 
idp14=find(T1>310 & T1<320 & dv1<msftcut);
idp24=find(T2>310 & T2<320 & dv2<msftcut);
idp34=find(T3>310 & T3<320 & dv3<msftcut);
idp44=find(T4>310 & T4<320 & dv4<msftcut);
idpLT4=find(LT(:,2)>310 & LT(:,2)<320 );

idp15=find(T1>290 & T1<300 & dv1<msftcut);
idp25=find(T2>290 & T2<300 & dv2<msftcut);
idp35=find(T3>290 & T3<300 & dv3<msftcut);
idp45=find(T4>290 & T4<300 & dv4<msftcut);
idpLT5=find(LT(:,2)>290 & LT(:,2)<300 );

idp16=find(T1>300 & T1<310 & dv1<msftcut);
idp26=find(T2>300 & T2<310 & dv2<msftcut);
idp36=find(T3>300 & T3<310 & dv3<msftcut);
idp46=find(T4>300 & T4<310 & dv4<msftcut);
idpLT6=find(LT(:,2)>300 & LT(:,2)<305 );

figure(12)
     j=[5 6 4 3 2 1];
for i=1:6
    subplot(2,3,i)
      eval(['id1=idp1' num2str(j(i)) ';'] );
      eval(['id2=idp2' num2str(j(i)) ';']);
      eval(['id3=idp3' num2str(j(i)) ';']);
      eval(['id4=idp4' num2str(j(i)) ';']);
      eval(['idLT=idpLT' num2str(j(i)) ';']);      
     pltwater(P1,P2,P3,P4,T1,T2,T3,T4,LT,delv1,delv2,delv3,delv4,delvLT,dv1,dv2,dv3,dv4,dvLT,id1,id2,id3,id4,idLT)
     xlim([-1 710])
     ylim([-4000 3000])
end

%
idp11=find( T1<255 & dv1<msftcut);
idp21=find( T2<255 & dv2<msftcut);
idp31=find(T3<255 & dv3<msftcut);
idp41=find( T4<255 & dv4<msftcut);
idpLT1=find(LT(:,2)<255 );

idp12=find(T1>255 & T1<260 & dv1<msftcut);
idp22=find(T2>255 & T2<260 & dv2<msftcut);
idp32=find(T3>255 & T3<260 & dv3<msftcut);
idp42=find(T4>255 & T4<260 & dv4<msftcut);
idpLT2=find(LT(:,2)>255 & LT(:,2)<260 );

idp13=find(T1>260 & T1<265 & dv1<msftcut);
idp23=find(T2>260 & T2<265 & dv2<msftcut);
idp33=find(T3>260 & T3<265 & dv3<msftcut);
idp43=find(T4>260 & T4<265 & dv4<msftcut);
idpLT3=find(LT(:,2)>260 & LT(:,2)<265 );
% 
idp14=find(T1>265 & T1<270 & dv1<msftcut);
idp24=find(T2>265 & T2<270 & dv2<msftcut);
idp34=find(T3>265 & T3<270 & dv3<msftcut);
idp44=find(T4>265 & T4<270 & dv4<msftcut);
idpLT4=find(LT(:,2)>265 & LT(:,2)<270 );

idp15=find(T1>270 & T1<276 & dv1<msftcut);
idp25=find(T2>270 & T2<276 & dv2<msftcut);
idp35=find(T3>270 & T3<276 & dv3<msftcut);
idp45=find(T4>270 & T4<276 & dv4<msftcut);
idpLT5=find(LT(:,2)>270 & LT(:,2)<276 );

idp16=find(T1>276 & T1<285 & dv1<msftcut);
idp26=find(T2>276 & T2<285 & dv2<msftcut);
idp36=find(T3>276 & T3<285 & dv3<msftcut);
idp46=find(T4>276 & T4<285 & dv4<msftcut);
idpLT6=find(LT(:,2)>276 & LT(:,2)<285 );

figure(13)

     j=[1 2 3 4 5 6];
for i=1:6

    subplot(2,3,i)
      eval(['id1=idp1' num2str(j(i)) ';'] );
      eval(['id2=idp2' num2str(j(i)) ';']);
      eval(['id3=idp3' num2str(j(i)) ';']);
      eval(['id4=idp4' num2str(j(i)) ';']);
      eval(['idLT=idpLT' num2str(j(i)) ';']);
      
      pltwater(P1,P2,P3,P4,T1,T2,T3,T4,LT,delv1,delv2,delv3,delv4,delvLT,dv1,dv2,dv3,dv4,dvLT,id1,id2,id3,id4,idLT)
     xlim([-1 710])
     ylim([-4000 3000])
end




%%
% Check of Heise vs Omega stability over time - appears that Heise is drifting

figure(100)
plot(P1,P1-P1H,'o',P2,P2-P2H+.7,'*',P3,P3-P3H,'s',P4,P4-P4H,'d')
plot(P1,P1-P1H,'o',P2,P2-P2H+.7,'*',P4,P4-P4H,'d')
ylim([-1 3])


%%
% plot data near 1 bar (<2 MPa)

figure(16)

id1=find(P1<2 & dv1<400);

id2=find(P2<2);
id3=find(P3<2);
id4=find(P4<2);
idLT=find(LT(:,1)<2.1);

errorbar((T1(id1)),delv1(id1),dv1(id1),'k<','markerfacecolor','k','Markersize',8)
hold on
errorbar((T2(id2)),delv2(id2),dv2(id2),'ks','markerfacecolor','k','Markersize',8)
errorbar((T3(id3)),delv3(id3),dv3(id3),'kd','markerfacecolor','k','Markersize',8)
errorbar((T4(id4)),delv4(id4),dv4(id4),'k^','markerfacecolor','k','Markersize',8)
errorbar(LT(idLT,2),delvLT(idLT),100*ones(size(idLT)),'ko','MarkerFaceColor','w','Markersize',8)
plot(LT(idLT,2),delvLT(idLT),'ko','MarkerFaceColor','w','Markersize',8)

plot([265 4750],[0 0],'k-','LineWidth',2)
hold off
xlim([265 475])
xlabel('Temperature (K)')
ylabel('(Exp-IAPWS)/Exp (ppm)')