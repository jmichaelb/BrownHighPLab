function UltraSonicStrc=Load_Window_Signal(filename,t_minus,duration,sampl_length,pltflg)
%function to load data from ocsilloscope files
%usage: [t,signal,ids]=Load_Window_Signal(filename,t_minus,duration,sampl_length)
% where the text "filename" is a file written by LABVIEW 
% t_minus and duration are in microseconds and set the beginning and
% duration of the window for the sources function
% this function assumes that the buffer rod 2-way time is about 54
% microseconds (needs to be changed for a new buffer rod) and that the
% first large signal is the reflection from the buffer rod.  A plot is made to
% show whether the assumptions are OK.

dt=.02;
if exist([filename '.mat'],'file')
    eval(['load ' filename ]);
    if exist('UltraSonicStrc','var')
        signal=UltraSonicStrc.signal;
        filename=UltraSonicStrc.filename;
        t=UltraSonicStrc.t;
        T=UltraSonicStrc.T;
        P=UltraSonicStrc.P;
        ids=UltraSonicStrc.ids;
    else
       UltraSonicStrc.filename=['Processed' filename];
       idu=strfind(filename,'_');
       idp=strfind(filename,'p');
       temp=filename;
       temp(idp(1))='.';
       temp(idp(2))='.';
       Tstr=temp((idu(1)+1):(idu(2)-1));
       T=str2num(Tstr);
       Pstr=temp((idu(2)+1):end);
       P=str2num(Pstr);
       [~,idm]=max(signal);
       id=find(signal> 0.2*signal(idm));
       start=idm-175 ;  % bufferrod two way time of about 54 microseconds
       signal=signal-mean(signal);
       siglength=length(signal(start:end));
       if (siglength<4096),
           signal=[signal(start:end)';zeros(4096-siglength,1)];
       else
           signal=signal(start:start+4095)';
       end     
       signal=signal/max(abs(signal));
       dt=dt*1e6;
       UltraSonicStrc.data=date;
       UltraSonicStrc.time=time;
    end
       t=dt*(1:4096);
else
    eval(['load ' filename ]);
    eval(['signal=' filename '(:,3);']);
    UltraSonicStrc.filename=['Processed' filename];
    idu=strfind(filename,'_');
    idp=strfind(filename,'p');
    temp=filename;
    temp(idp(1))='.';
    temp(idp(2))='.';
    Tstr=temp((idu(1)+1):(idu(2)-1));
    T=str2num(Tstr);
    Pstr=temp((idu(2)+1):end);
    P=str2num(Pstr);
    [~,idm]=max(signal);
    id=find(signal> 0.2*signal(idm));

    start=id(1) + 53.5/dt;  % bufferrod two way time of about 54 microseconds
    signal=signal(start:(start+4095));
    signal=signal-mean(signal);
    signal=signal/max(abs(signal));
    t=dt*(1:4096);
end
idminus=fix(t_minus/dt);
[~,idmax]=max(signal);
ids=((idmax-idminus):(idmax-idminus+duration/dt));
nfft=2*2048;
FY=(0:(nfft-1))/nfft/dt;

YS=fft(signal(ids),nfft);
if pltflg=='y'
scrsz=get(0,'ScreenSize');
figsz=[1 .8*scrsz(4) 3*scrsz(3)/4 .8*scrsz(4)];
figure('Name',UltraSonicStrc.filename,'Position',figsz);
subplot(211)
plot(t(1:length(signal)),signal)
xlabel('time (microsec)')

subplot(223)
plot(t(ids),signal(ids));
xlabel('time (microsec)')
subplot(224)
plot(FY(200:600),abs(YS(200:600).^2)/max(abs(YS(200:600).^2)))
xlabel('frequency (MHz)')
end


UltraSonicStrc.t=t;
UltraSonicStrc.signal=signal;
UltraSonicStrc.ids=ids;
UltraSonicStrc.T=T;
UltraSonicStrc.P=P;
UltraSonicStrc.sampl_length=sampl_length;

%eval(['save ' UltraSonicStrc.filename ' UltraSonicStrc'])






