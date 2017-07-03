%function PressureT
[pde_fig,ax]=pdeinit;
pdetool('appl_cb',2);
set(ax,'DataAspectRatio',[1 1 1]);
set(ax,'PlotBoxAspectRatio',[1 1 1]);
set(ax,'XLim',[-.01 .15]);
set(ax,'YLim',[ -.65 0]);
set(ax,'XTickMode','auto');
set(ax,'YTickMode','auto');


pdepoly([pol{1}(1:end-1,1)],[pol{1}(1:end-1,2)],'Ti-end')
pdepoly([pol{2}(1:end-1,1)],[pol{2}(1:end-1,2)],'sample')
pdepoly([pol{3}(1:end-1,1)],[pol{3}(1:end-1,2)],'air')
pdepoly([pol{4}(1:end-1,1)],[pol{4}(1:end-1,2)],'airgel')
pdepoly([pol{5}(1:end-1,1)],[pol{5}(1:end-1,2)],'upper insulation')
pdepoly([pol{6}(1:end-1,1)],[pol{6}(1:end-1,2)],'steel')
pdepoly([pol{8}(1:end-1,1)],[pol{8}(1:end-1,2)],'lower insulation')
pdepoly([pol{9}(1:end-1,1)],[pol{9}(1:end-1,2)],'side insulation')
pdepoly([pol{10}(1:end-1,1)],[pol{10}(1:end-1,2)],'aluminum')
pdepoly([pol{11}(1:end-1,1)],[pol{11}(1:end-1,2)],'center insulation')

%