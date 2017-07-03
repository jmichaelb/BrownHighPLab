
numberOfPDE = 10;
pdem = createpde(numberOfPDE);

%  end closure
   p1=[
         0   -0.0711
    0.0061   -0.0711
    0.0061   -0.1638
    0.0175   -0.1638
    0.0175   -0.1748
    0.0124   -0.1829
    0.0124   -0.1877
    0.0107   -0.1900
    0.0107   -0.2154
         0   -0.2154
]; 
% air gap 
 p2=[  
     0      -0.2154
    0.0056   -0.2154
    0.0056   -0.2261
         0   -0.2261
];
%sample
p3=[ 
    0.0061   -0.0780
    0.0081   -0.0780
    0.0081   -0.1638
    0.0061   -0.1638
];
%super insulation
p4=[    0.0505   -0.1397
    0.0759   -0.1397
    0.0759   -0.1270
    0.0505   -0.1270
];
%upper insulation
p5=[    0.0505   -0.1270
    0.0759   -0.1270
    0.0759   -0.0610
    0.0328   -0.0610
    0.0328   -0.0711
    0.0061   -0.0711
    0.0061   -0.0780
    0.0251   -0.0780
    0.0251   -0.0991
    0.0505   -0.0991

    ];
%steel
p6=[    0   -0.6096
    0.0051   -0.6096
    0.0051   -0.4724
    0.0150   -0.4724
    0.0150   -0.4445
    0.0505   -0.4445
    0.0505   -0.4039
    0.0759   -0.4039
    0.0759   -0.1397
    0.0505   -0.1397
    0.0505   -0.0991
    0.0251   -0.0991
    0.0251   -0.0780
    0.0081   -0.0780
    0.0081   -0.1638
    0.0175   -0.1638
    0.0175   -0.1748
    0.0124   -0.1829
    0.0124   -0.1877
    0.0107   -0.1900
    0.0107   -0.2154
    0.0056   -0.2154
    0.0056   -0.2261
         0   -0.2261
];
%  %outer limits    
% p7=[   0   -0.6096
%     0.0328   -0.6096
%     0.0328   -0.5080
%     0.0963   -0.5080
%     0.0963   -0.4039
%     0.0759   -0.4039
%     0.0759   -0.1397
%     0.0759   -0.0610
%     0.0328   -0.0610
%     0.0328   -0.0711
%     0.0053   -0.0711
%          0   -0.0711
% ];
%lower insulation
p8=[
    0.0051   -0.6096
    0.0328   -0.6096
    0.0328   -0.4978
    0.0051   -0.4978
];
%side insulation
p9=[
    0.0328   -0.5080
    0.0963   -0.5080
    0.0963   -0.4039
    0.0759   -0.4039
    0.0505   -0.4039
    0.0505   -0.4140
    0.0848   -0.4140
    0.0848   -0.4978
    0.0328   -0.4978
];
%aluminum
p10=[    0.0505   -0.4204
    0.0790   -0.4204
    0.0790   -0.4978
    0.0848   -0.4978
    0.0848   -0.4140
    0.0505   -0.4140
];

%inside insulation
p11=[
    0.0051   -0.4978
    0.0790   -0.4978
    0.0790   -0.4204
    0.0505   -0.4204
    0.0505   -0.4445
    0.0150   -0.4445
    0.0150   -0.4724
    0.0051   -0.4724
];

nmax=length(p6(:,1));
n1=length(p1(:,1));
n2=length(p2(:,1));
n3=length(p3(:,1));
n4=length(p4(:,1));
n5=length(p5(:,1));
n6=length(p6(:,1));
n8=length(p8(:,1));
n9=length(p9(:,1));
n10=length(p10(:,1));
n11=length(p11(:,1));

 r1=[2 n1 p1(:,1)' p1(:,2)' zeros(1,2*(nmax-n1))];
  r2=[2 n2 p2(:,1)' p2(:,2)' zeros(1,2*(nmax-n2))];
   r3=[2 n3 p3(:,1)' p3(:,2)' zeros(1,2*(nmax-n3))];
    r4=[2 n4 p4(:,1)' p4(:,2)' zeros(1,2*(nmax-n4))];
     r5=[2 n5 p5(:,1)' p5(:,2)' zeros(1,2*(nmax-n5))];
      r6=[2 n6 p6(:,1)' p6(:,2)' zeros(1,2*(nmax-n6))];
       %r7=[2 n7 p7(:,1)' p7(:,2)' zeros(1,abs(nmax-n7))];
        r8=[2 n8 p8(:,1)' p8(:,2)' zeros(1,2*(nmax-n8))];
         r9=[2 n9 p9(:,1)' p9(:,2)' zeros(1,2*(nmax-n9))];
          r10=[2 n10 p10(:,1)' p10(:,2)' zeros(1,2*(nmax-n10))];
           r11=[2 n11 p11(:,1)' p11(:,2)' zeros(1,2*(nmax-n11))];
gdm=[r1' r2' r3' r4' r5' r6' r8' r9' r10' r11'];
txt1='Ti+AR+SM+SI+UI+ST+LI+BI+Al+CI';
txt2=['Ti';'AR';'SM';'SI';'UI';'ST';'LI';'BI';'Al';'CI']';
g=decsg(gdm,txt1,txt2);
geometryFromEdges(pdem, g);
% Generate the mesh
hmax = .01; % element size
generateMesh(pdem, 'Hmax', hmax);
figure;
pdeplot(pdem);
axis equal
title 'System With Triangular Element Mesh'
%pdegplot(g,'EdgeLabels','on','SubdomainLabels','on')
%%
% BC - axis:  29, 30 31  % BC - no flow 11 10 35
% BC - room T : 32 33 36 2 3 1 38 6 5
% set T at 9
RoomT=21;
SetT=-20;
applyBoundaryCondition(pdem,'Edge',[1 2 3 5 6 32 33 36  38] , 'u', RoomT);
applyBoundaryCondition(pdem,'Edge',9 , 'u', SetT);

% 1 is air gel
% 2 is TiAl
% 3 7 9 10 are foam
% 4 is air
% 5 is steel
% 6 is sample
% 8 is Al
k = [.01 6 .04 .001 25 .1 .04 70 ]; % thermal conductivity, W/(m-degree C)

% PDE Toolbox allows the coefficients to be input as string expressions
c=char(sprintf('%g*x ', k(1)),sprintf('%g*x ', k(2)),sprintf('%g*x ', k(3)),sprintf('%g*x ', k(3)),sprintf('%g*x ', k(5)),sprintf('%g*x ', k(6)),...
sprintf('%g*x ', k(7)),sprintf('%g*x ', k(8)),sprintf('%g*x ', k(3)),sprintf('%g*x ', k(3)));
f = zeros(10,1); % heat source, W/m^3
a = zeros(10,1);

u = assempde(pdem,c,a,f);
figure;
pdeplot(pdem, 'xydata', u, 'contour', 'on');
axis equal
title 'Steady State Temperature';




