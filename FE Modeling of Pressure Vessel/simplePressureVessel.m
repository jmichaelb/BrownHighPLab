numberOfPDE = 2;
pdem = createpde(numberOfPDE);
%units of meters
%the problem is a cylinder with insulation at top and bottom (no flow through midline)
% that is cooled on sides and remains at room temperature at ends of cylinder

%insulation specified as polygon
p1=[    0        0
      0.08     0
      0.08    -0.025
      0       -0.025
];
%steel specified as polygon
p2=[    0      -0.025
      0.08     -0.025
      0.08     -0.1
      0.0      -0.1
];

 r1=[2 4 p1(:,1)' p1(:,2)' ];
 r2=[2 4 p2(:,1)' p2(:,2)' ];

gdm=[r1' r2'];
txt1='R1+R2';
txt2=['R1';'R2']';
g=decsg(gdm,txt1,txt2);
geometryFromEdges(pdem, g);
% Generate the mesh
hmax = .005; % element size of 5 mm
generateMesh(pdem, 'Hmax', hmax);
figure;
pdeplot(pdem);
axis equal
title 'System With  Mesh'
%pdegplot(g,'EdgeLabels','on','SubdomainLabels','on')

RoomT=21;
SetT=-20;
applyBoundaryCondition(pdem,'Edge',1  ,'u', RoomT );
applyBoundaryCondition(pdem,'Edge',4 , 'u', SetT );

k = [.01 25 ]; % thermal conductivity, W/(m-degree C)
c=char(sprintf('%g*x ', k(1)),sprintf('%g*x ', k(2)));
f = zeros(2,1); % no heat source, W/m^3
a =0;  % zeros(2,1); % 
u = assempde(pdem,c,a,f);


figure;
pdeplot(pdem, 'xydata', u, 'contour', 'on');
axis equal
title 'Steady State Temperature';




