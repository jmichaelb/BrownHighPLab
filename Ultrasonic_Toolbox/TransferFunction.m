function UltraSonicStrc=TransferFunction(UltraSonicStrc,lambda,flg_decon,pkflg,nsec)
%function to deconvolve the ultrasonic signal using a time domain
%deconvolution technique
% Usage:
%     TF=TransferFunction(UltraSonicStrc,lambda,flg_decon,pkflg,nsec)
%  where all the data are in the structure UltraSonicStrc lambda is the
%  damping and flg_deconv can be set to "FD" or "TD" - FD is faster pkflg=
%  'e','a','p' for existing,automatic or hand pick and nsec is the number
%  of sections to divide the signal for the TD deconvolution - more
%  sections is faster (1, 2 and 4 are choices).

signal=UltraSonicStrc.signal(:);
t=UltraSonicStrc.t;
T=UltraSonicStrc.T;
P=UltraSonicStrc.P;
ids=UltraSonicStrc.ids;
sampl_length=UltraSonicStrc.sampl_length;
filename=UltraSonicStrc.filename;
npt=length(signal);
npts=fix(npt/nsec);
source=[signal(ids); zeros(npts-length(ids),1)];

switch flg_decon
    case 'TD'
        %time domain deconvolution
        TF=zeros(npt,1);
        for isect=1:nsec,
            smat=zeros(npts,npts);
            smat(:,1)=source(:);
            for i=2:npts
             smat(:,i)=circshift(source,[i-1 0]);
            end
            A=sparse([smat;lambda*eye(npts)]);
            index=(1:npts)+npts*(isect-1);
            TF(index)=A\[signal(index);zeros(npts,1)]; 
        end
     case 'FD'
        % frequency domain deconvolution
         Y=fft(signal,npt);
         H=fft(source,npt);
         %apply water level damping
          %by constructing successive water level patched spectra, gwspec (wlev increasing)
         for i=1:length(H)
             if abs(H(i)) < lambda
                 H(i,1)=lambda*(H(i)./abs(H(i)));
             else
                 H(i,1)=H(i);
             end   
         end
         TF=ifft(Y./(H),npt);      
end

TF=TF/max(abs(TF));
%filter coefficients for a band pass filter - 5 to 12 MHz
%  [B,A] = butter(2,[.2 .5]);
 B=[   0.1311         0   -0.2622    0.0000    0.1311]; 
 A=[ 1.0000   -1.4001    1.2722   -0.6584    0.2722];
 TF=Brown_filter(B,A,TF);
 
 %if not(isfield(UltraSonicStrc,'pks'))
 switch pkflg
     case 'p'
       scrsz=get(0,'ScreenSize');
       figsz=[1 .8*scrsz(4) 3*scrsz(3)/4 .8*scrsz(4)];
        figure1=figure('Name','Click on Data Peaks','Position',figsz);
        pks=myplot(UltraSonicStrc.t,TF);
        close(figure1)
     case 'e'
        pks=UltraSonicStrc.pks;
     case 'a'
         [~,~,~,~,~,~,veliapws]=IAPWS(P/1e3,273.15+T);
         pks=.8+[0 (veliapws)^(-1)*sampl_length*(2:2:12)]  ;
         pks=pks(pks<t(end));
 end
 
 npks=length(pks);
 for i=1:npks
    id=find(t>pks(i)-1 & t<pks(i)+1);
    if i==1,
        [~,idx]=min(-TF(id));
    else
        [~,idx]=min(TF(id));
    end
    pks(i)=t(id(idx));
 end
 UltraSonicStrc.pks=pks;
 UltraSonicStrc.TF=TF;
 UltraSonicStrc.flg_decon=flg_decon;
 UltraSonicStrc.lambda=lambda;
 UltraSonicStrc.pkflg=pkflg;
 
%eval(['save ' filename ' UltraSonicStrc'])