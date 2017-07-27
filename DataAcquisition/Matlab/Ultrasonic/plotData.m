
% Loading UW data from experiment folder
foldername = pwd;
id = find(foldername == '/');

dataName = foldername(id(end):end); %'20170130_H2O_NaCl_03m';
load(strcat(foldername,'/', dataName))

tempdata = data;
id = find(isempty([tempdata.Omega1]));

% Scatter plot of UW data
figure('units','normalized','position',[.5 .5 .4 1])

subplot(311)
scatter3([tempdata.Omega1], [tempdata.Ch2], [tempdata.SoundSpeed],'filled')
xlabel('P')
ylabel('T')
zlabel('Vel')
title('3M NaCl')

% Scatter plot of UW tempdata with spline fit190
subplot(312)
scatter3([tempdata.Omega1], [tempdata.Ch2], [tempdata.SoundSpeed],'filled')
hold on
npc=20; % Pressure control points (x axis)
ntc=15; % Temperature control points (y axis)
x = horzcat([tempdata.Omega1]',[tempdata.Ch2]');
y = [tempdata.SoundSpeed]';
Xc=linspace(min([tempdata.Omega1]')-5,max([tempdata.Omega1]')+5,npc); 
Yc=linspace(min([tempdata.Ch2]')-3,max([tempdata.Ch2]')+3,ntc);
lam=60*[.3 .2];
RegFac=[1 1]; 
Ordr=[4 4];
mdrv=[2 2];
uncert = [tempdata.SoundSpeed]*4e-5; %[tempdata.delVel];
id=find(isnan(x(:,1)) |isnan(x(:,2)));
mask=ones(size(y));
mask(id)=nan;
UW = spdft(x,y,uncert,{Xc,Yc},lam,RegFac,Ordr,mdrv,mask);
fnplt(UW)
shading 'flat'
xlabel('P')
ylabel('T')
zlabel('Vel')

% Scatter of surface devs (%) from surface
subplot(313)

r = {};
g = {};
b = {};
for i = 1:length({tempdata.delVel})
    if ~isempty(tempdata(i).delVel)
        if tempdata(i).delVel >.42
            r{i} = 1;
            g{i} = 0;
            b{i} = 0;
        elseif tempdata(i).delVel <=.42 && tempdata(i).delVel >= .20
            g{i} = 1;
            b{i} = 0;
            r{i} = 0;
        else 
            b{i} = 1;
            g{i} = 0;
            r{i} = 0;
        end
    end
end

r = cell2mat(r);
r = r';
g = cell2mat(g);
g = g';
b = cell2mat(b);
b = b';

colors = horzcat(r,g,b);
        

percentdevs = 100*(UW.Data.devs./[tempdata.SoundSpeed]');
scatter3([tempdata.Omega1], [tempdata.Ch2], percentdevs(:), 36, colors,'filled');
xlabel('P')
ylabel('T')
zlabel('% dev from surface')
title('red: misfit > .40 | green: misfit < .40 | blue: misfit < .20') 


%%

% Surface curvature plots
 figure('units','normalized','position',[.5 .5 .4 1])
subplot(211)
fnplt(fnder(UW,[0 2]))
title('dp^2')
subplot(212)
fnplt(fnder(UW, [2 0]))
title('dt^2')

%% pressure gauges:

 

%Adding old pure water data

    file = fopen('/Users/common/Desktop/UW_rawdata copy.txt');
    oldData = textscan(file, '%s %s %s %s %s %s %s %s %s %s %s');
    fclose(file);

    oldOmega1temp = {};
    for i = 1:length(oldData{1})
        oldOmega1temp{i} = sprintf('%s.%s', cell2mat(oldData{7}(i)), cell2mat(oldData{8}(i)));
    end

    oldHeise1temp = oldData{9};
    oldHeise2temp = oldData{10};

    oldOmega1 = [];
    oldHeise1 = [];
    oldHeise2 = [];
    for i = 1:length(oldHeise1temp)
        if ~isequal(oldOmega1temp{i}, 'NAN') && ~isequal(oldHeise1temp{i}, 'NAN') && ~isequal(oldHeise2temp{i}, 'NAN')
        oldOmega1(end+1) = str2num(oldOmega1temp{i});
        oldHeise1(end+1) = str2num(oldHeise1temp{i});
        oldHeise2(end+1) = str2num(oldHeise2temp{i});
        end
    end

    %clearvars -except oldOmega1 oldHeise1 oldHeise2
figure    
plot(oldOmega1, oldOmega1-oldHeise1, 'g*')
hold on
plot(oldOmega1, oldOmega1-oldHeise2, 'r*')
hold on
plot([tempdata.Omega1], [tempdata.Omega1]-[tempdata.Heise1], 'ko', 'MarkerFaceColor', 'k');
hold on
plot([tempdata.Omega1], [tempdata.Omega1]-[tempdata.Heise2], 'o');
xlabel('Omega1 [MPa]')
ylabel('Omega1 minus Heise1 & Heise2 [MPa]')
legend('Omega1 - Heise1', 'Omega1 - Heise2')

legend('NEW Omega1 - Heise1', 'NEW Omega1 - Heise2', 'OLD Omega1 - Heise1', 'OLD Omega1 - Heise2')

