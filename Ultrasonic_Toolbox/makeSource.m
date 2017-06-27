function s=makeSource(dt,duration,f_start, f_end,nfft,type)

% make a source function

t=0:dt:duration;
npts=length(t)
if strncmp(type,'p',1)
    w= prolate(npts)';
    w=w/max(w);
elseif strncmp(type,'g',1)
    w=gaussian(t,t(round(npts/2)),t(round(npts/5)),1);
    w=4-3*w;
elseif strncmp(type,'b',1)
    w=ones(size(t));
end
% plot(t,w)
% pause

df=f_end-f_start;
f=f_start+df*t/duration;

s=w.*sin(2*pi*f.*t);
s=[s zeros(1,nfft-npts)];


