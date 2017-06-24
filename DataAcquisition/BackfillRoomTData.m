% Backfill Room Temperature data

% parameters
earliestExp = datetime(2017,1,1);
ultraSonicDataDir = '/Users/pennyespinoza/iSchool/BrownLab/Data/Ultrasonic Data/';

% check that folder exists
assert(exist(ultraSonicDataDir,'dir')==7, 'The UltraSonicData directory does not exist');
    
% get list of subdirs
yyyymmddRE = '201[4-7][01][0-9][0-3][0-9]';
yyyymmddFmt = 'yyyyMMdd';
exps = dir(replace(ultraSonicDataDir,'%20',' '));

% add a new field with the date for each subdir, if any
expDates = num2cell(datetime(cellfun(@(c)(regexp(c,strcat('^',yyyymmddRE),'match','once')),...
    {exps.name},'UniformOutput',0),'InputFormat',yyyymmddFmt));
[exps(:).expStartDate] = expDates{:};

% toss directories for experiments predating earliestExp or that have no
% date
exps = exps([exps.isdir]==1 & ~isnat([exps.expStartDate]) & [exps.expStartDate]>=earliestExp(1));
    
% order directories with latest first, oldest last

% for each directory
    % load UltraSonicStrc database
    % for each distinct date
        % import/load CH3 data for the date
        % for each spectra on that date (latest to oldest)
            % if RoomT is empty
                % determine date/time for spectra
                % select range of log entries surrounding the spectra
                % discard zeros
                % calculate RoomT average
                % fit log data
                % update database RoomT and RoomTSTD
                % save database
    

