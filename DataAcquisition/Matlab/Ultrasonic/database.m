% To be run concurently with DataAcquisition script

%% Prompts user for Heise 1 and Heise 2 values, adds data to structure

    
    Heise1 = input('\n\nEnter a Heise 1 value: ');
    Heise2 = input('Enter a Heise 2 value: ');
    spectratime = sprintf('%s %s', date, time);
    
    % Creating file name for saving and to check to see if structure
    % already exists
    filesave = pwd;
    id = find(filesave == '/');
    filesave = filesave(id(end)+1:end);
    x = dir;
        
        for i = 1:length({x.name})
            if isequal(x(i).name, strcat(filesave,'.mat'))
               check = 1; 
            end
        end
    
        interpO2 = [];
        O2STD = [];

        if ~ exist('check') 

            data = struct('Filename', filename, 'SpectraTime', spectratime, 'Omega1', interpO1, 'Omega2', interpO2, 'Heise1', Heise1, 'Heise2', Heise2,...
                              'Ch2', interpCh2, 'SoundSpeed', UltraSonicStrc.vel, 'Omega1STD', O1STD, 'Omega2STD', O2STD, 'Ch2STD', Ch2STD, 'delVel', UltraSonicStrc.del_vel, 'RoomT', interpRoomT, 'RoomTSTD', RoomTSTD);
            
            save(filesave,'data')
        else

            load(filesave)
            
            data(spectraNum).Filename = filename;
            data(spectraNum).SpectraTime = spectratime;
            data(spectraNum).Omega1 = interpO1;
            data(spectraNum).Omega2 = interpO2;
                % If something is entered for Heise, use the values in the structure.
                % If nothing is entered, leave the structure as is. 
                if ~isempty(Heise1) || ~isempty(Heise2)
                    data(spectraNum).Heise1 = Heise1;
                    data(spectraNum).Heise2 = Heise2;
                end
                
            data(spectraNum).Ch2 = interpCh2;
            data(spectraNum).SoundSpeed = UltraSonicStrc.vel;
            data(spectraNum).Omega1STD = O1STD;
            data(spectraNum).Omega2STD = O2STD;
            data(spectraNum).Ch2STD = Ch2STD;
            data(spectraNum).delVel = UltraSonicStrc.del_vel;
            data(spectraNum).roomT = interpRoomT;
            data(spectraNum).roomTSTD = RoomTSTD;
            
            save(filesave, 'data')

        end
    