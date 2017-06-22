% Backfill Room Temperature data

% parameters
earliestExp = '2017/01/01';
ultraSonicDataDir = '/Users/penny/Documents/iSchool/BrownLab/Data/UltrasonicData';

% check that folder exists
% get list of subdirs
% get date for each subdir
% toss directories for experiments predating earliestExp
% order directories with latest first, oldest last

% for each directory
    % load UltraSonicStrc database
    % for each spectra in database
        % if RoomT is empty
            % determine date/time for spectra
            % import/load CH3 data for the date
            % select range of log entries surrounding the spectra
            % discard zeros
            % calculate RoomT average
            % fit log data
            % update database RoomT and RoomTSTD
            % save database
    

