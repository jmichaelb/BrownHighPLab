% Backfill Room Temperature data
clear all; clc

% parameters
earliestExp = datetime(2017,5,1);
ultraSonicDataDir = '/Users/penny/Documents/iSchool/BrownLab/Data/Ultrasonic Data/';

% check that folder exists
assert(exist(replace(ultraSonicDataDir,'%20',' '),'dir')==7, 'The UltraSonicData directory does not exist');
    
% get list of subdirs
yyyymmddRE = '201[4-7][01][0-9][0-3][0-9]';
yyyymmddFmt = 'yyyyMMdd';
exps = dir(replace(ultraSonicDataDir,'%20',' '));

% add a new field with the date for each subdir, if any
expDates = datetime(cellfun(@(c)(regexp(c,strcat('^',yyyymmddRE),'match','once')),...
    {exps.name},'UniformOutput',0),'InputFormat',yyyymmddFmt);
expDates = num2cell(expDates);
[exps(:).expStartDate] = expDates{:};

% toss directories for experiments predating earliestExp or that have no date
exps = exps([exps.isdir]==1 & ~isnat([exps.expStartDate]) & [exps.expStartDate]>=earliestExp(1));
    
% for each directory (latest first, oldest last)
specTimeFmt = 'M/d/yyyy h:mm:ss a';
specDateStr = 'yyyymmdd';
roomTTimeFmt = 'h:mm:ss.SSS a M/d/yyyy ';
omega1FileSuffix = '_100KPSI_OLD.txt';
roomTFileSuffix = '_CH3.txt';
roomTField = 'RoomT';
roomTStdField = 'RoomTSTD';
halfPtsToAvg = 5;
for ed = sort([exps.expStartDate],'descend')
    exp = exps([exps.expStartDate]==ed);
    disp(['Backfilling data for experiment ' exp.name]);
    % load UltraSonicStrc database
    expPath = strcat(ultraSonicDataDir,exp.name,'/');
    expDbFile = strcat(expPath,exp.name,'.mat');
    try
        load(expDbFile);    % loads into a variable 'data'
    catch ME
        warning(['Unable to load db for ' expPath]);
        continue    % go on to next experiment
    end
    rtFieldExists = isfield(data,'RoomT');
    lastRoomTDate = datetime('tomorrow');
    % for each spectrum 
    for specNum = 1:length(data)
        spec = data(specNum);
        % only do anything if RoomT is empty or does not exist
        if(~rtFieldExists || isempty(spec.RoomT))
            %try
                % determine date/time for spectra
                disp(['    Processing spectrum ' spec.Filename ' (' spec.SpectraTime ')']);
                specTime = datetime(spec.SpectraTime,'InputFormat',specTimeFmt);
                % import Omega1 and CH3 data for the day (if not already loaded)
                % omega1 data needed to determine if any data s/b discarded
                loadRoomTDate = datetime(datestr(specTime,specDateStr),'InputFormat',yyyymmddFmt);
                % if the specTime is before 3 am, load the previous day's
                % room T data
                if(hour(specTime) < 3)
                    loadRoomTDate = datetime(addtodate(datenum(loadRoomTDate),-1,'day'),'ConvertFrom','datenum');
                    disp(['        Since spectrum is before 3 am, using roomT data for ' datestr(loadRoomTDate,specDateStr)]);
                end
                if(lastRoomTDate ~= loadRoomTDate)
                    missingData = 0;
                    lastRoomTDate = loadRoomTDate;
                    dStr = datestr(lastRoomTDate,specDateStr);
                    % import CH3 and Omega1 data for the date
                    roomTFile = strcat(expPath,dStr,roomTFileSuffix);
                    omega1File = strcat(expPath,dStr,omega1FileSuffix);
                    
                    % skip this spectrum if the needed files are missing
                    if(exist(roomTFile,'file')~=2 || exist(omega1File,'file')~=2)
                        warning(['Cannot find ' dStr ' CH3 or Omega1 file']);
                        missingData = 1;
                        continue
                    end
                    
                    disp(['        Loading CH3 and Omega1 data for ' dStr]);
                    roomTData = importdata(roomTFile,'\t');
                    omega1Data = importdata(omega1File);
                    
                    roomT = struct('time',datetime(roomTData.textdata,'InputFormat',roomTTimeFmt),...
                        'temp',roomTData.data);
                    omega1 = struct('time',datetime(omega1Data.textdata,'InputFormat',roomTTimeFmt),...
                        'pres',omega1Data.data(:,2));
                end % end if(lastRoomTDate ~= loadRoomTDate)
                
                if(missingData == 1) % this will persist if the same file is sought 
                    warning(['Missing T or P data - skipping spectrum ' spec.Filename]);
                    continue
                end
                % select range of log entries surrounding the spectra
                [~,roomTIdx] = min(abs(roomT.time - specTime));
                [~,omega1Idx] = min(abs(omega1.time - specTime));
                % use a new construct for this spectra so you don't have to
                % reload all the room T data for the date
                specRoomTimes = roomT.time(roomTIdx-halfPtsToAvg:roomTIdx+halfPtsToAvg);
                specRoomTemps = roomT.temp(roomTIdx-halfPtsToAvg:roomTIdx+halfPtsToAvg);
                specPressures = omega1.pres(omega1Idx-halfPtsToAvg:omega1Idx+halfPtsToAvg);
                % ignore data points corresponding to Omega1 0 pressures
                hasValidP = find(specPressures ~= 0);
                specRoomTimes = specRoomTimes(hasValidP);
                specRoomTemps = specRoomTemps(hasValidP);
                % fit log data (assume the specTime is the 0 time)
                specRoomTTimeOffsets = etime(datevec(specRoomTimes),datevec(specTime));
                fitCoeffs = polyfit(specRoomTTimeOffsets,specRoomTemps,1);
                interpRoomT = polyval(fitCoeffs,0); % get interpolated roomT for time = 0
                roomTStd = std(specRoomTemps);
                % update database RoomT and RoomTSTD
                data(specNum).RoomT = interpRoomT;
                data(specNum).RoomTSTD = roomTStd;
                % save database
                save(expDbFile, 'data');
%             catch ME
%                 warning(['!!!!!!!!!! Could not process spectrum ' spec.Filename '!!!!!!!!!!']);
%                 disp(['    ' ME.message]);
%                 disp(['    ' ME.cause]);
%             end % end main try for processing spectrum
        end % end if(~rtFieldExists || spec.RoomT=[])
    
    
    end % end for spec = data
end % end for ed = sort([exps.expStartDate],'descend')
    

