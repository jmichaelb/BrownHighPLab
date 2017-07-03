% This script is written and read by pdetool and should NOT be edited.
% There are two recommended alternatives:
 % 1) Export the required variables from pdetool and create a MATLAB script
 %    to perform operations on these.
 % 2) Define the problem completely using a MATLAB script. See
 %    http://www.mathworks.com/help/pde/examples/index.html for examples
 %    of this approach.
%function pdemodel
[pde_fig,ax]=pdeinit;
pdetool('appl_cb',9);
set(ax,'DataAspectRatio',[1 1 1]);
set(ax,'PlotBoxAspectRatio',[1 1 1]);
set(ax,'XLim',[-0.01 0.14999999999999999]);
set(ax,'YLim',[-0.59999999999999998 0.01]);
set(ax,'XTickMode','auto');
set(ax,'YTickMode','auto');

% Geometry description:
pdepoly([          0
    0.0061
    0.0061
    0.0175
    0.0175
    0.0124
    0.0124
    0.0107
    0.0107
         0
],...
[  -0.0711
   -0.0711
   -0.1638
   -0.1638
   -0.1748
   -0.1829
   -0.1877
   -0.1900
   -0.2154
   -0.2154
],...
 'Tiend');
pdepoly([
         0
    0.0056
    0.0056
         0.
],...
[  -0.2154
   -0.2154
   -0.2261
   -0.2261
],...
 'air');

pdepoly([  0.0061
    0.0081
    0.0081
    0.0061
],...
[  -0.0780
   -0.0780
   -0.1638
   -0.1638
],...
 'sample');

pdepoly([0.0505
    0.0759
    0.0759
    0.0505
],...
[  -0.1397
   -0.1397
   -0.1270
   -0.1270
],...
 'airgel');

pdepoly([ 
    0.0505
    0.0759
    0.0759
    0.0328
    0.0328
    0.0061
    0.0061
    0.0251
    0.0251
    0.0505
],...
[    -0.1270
   -0.1270
   -0.0610
   -0.0610
   -0.0711
   -0.0711
   -0.0780
   -0.0780
   -0.0991
   -0.0991
],...
 'upperinsulation');

pdepoly([          0
    0.00
    0.0048
    0.0150
    0.0150
    0.0505
    0.0505
    0.0759
    0.0759
    0.0505
    0.0505
    0.0251
    0.0251
    0.0081
    0.0081
    0.0175
    0.0175
    0.0124
    0.0124
    0.0107
    0.0107
    0.0056
    0.0056
         0
],...
[   -0.6096
   -0.6096
   -0.4724
   -0.4724
   -0.4445
   -0.4445
   -0.4039
   -0.4039
   -0.1397
   -0.1397
   -0.0991
   -0.0991
   -0.0780
   -0.0780
   -0.1638
   -0.1638
   -0.1748
   -0.1829
   -0.1877
   -0.1900
   -0.2154
   -0.2154
   -0.2261
   -0.2261
],...
 'steel');

pdepoly([ 0.0048
    0.0328
    0.0328
    0.0048
],...
[    -0.6096
   -0.6096
   -0.4978
   -0.4978
],...
 'lowerinsulation');

pdepoly([0.0328
    0.0963
    0.0963
    0.0759
    0.0505
    0.0505
    0.0848
    0.0848
    0.0328
],...
[  -0.5080
   -0.5080
   -0.4039
   -0.4039
   -0.4039
   -0.4140
   -0.4140
   -0.4978
   -0.4978
],...
 'sideinsulation');
pdepoly([ 0.0505
    0.0790
    0.0790
    0.0848
    0.0848
    0.0505
],...
[  -0.4204
   -0.4204
   -0.4981
   -0.4981
   -0.4140
   -0.4140
],...
 'aluminum');
pdepoly([    0.0048
    0.0790
    0.0790
    0.0505
    0.0505
    0.0150
    0.0150
    0.0048
],...
[    -0.4978
   -0.4978
   -0.4204
   -0.4204
   -0.4445
   -0.4445
   -0.4724
   -0.4724
],...
 'insideinsulation');
set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','P1+P2+P3+P4+P5+P6+P7+P8+P9+P10')

% PDE coefficients:
pdeseteq(1,...
'1.0',...
'1.0',...
'(1.0)+(1.0).*(0.0)',...
'(1.0).*(1.0)',...
'0:10',...
'0.0',...
'0.0',...
'[0 100]')
setappdata(pde_fig,'currparam',...
['1.0';...
'1.0';...
'1.0';...
'1.0';...
'1.0';...
'0.0'])

% Solve parameters:
setappdata(pde_fig,'solveparam',...
char('0','1000','10','pdeadworst',...
'0.5','longest','0','1E-4','','fixed','Inf'))

% Plotflags and user data strings:
setappdata(pde_fig,'plotflags',[1 1 1 1 1 1 1 1 0 0 0 1 1 0 0 0 0 1]);
setappdata(pde_fig,'colstring','');
setappdata(pde_fig,'arrowstring','');
setappdata(pde_fig,'deformstring','');
setappdata(pde_fig,'heightstring','');
