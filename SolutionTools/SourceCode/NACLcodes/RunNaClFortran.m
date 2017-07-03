function Archer=RunNaClFortran(PTm)
% this function is a frontend to the batch FORTRAN code of Archer. The
% input conditions of P, T, and m are in a cell. which is then converted
% into a list of PTm points that are saved in an ascii file and then read
% in when the code is executed.  The code saves an ascii file that is then
% read back into MATLAB.  the temporary files are removed.
% Usage:
%             [rhos,gam,phi,aw,AV,alpha,beta,Hr,ACp,rhow,alphas,alphaw,betas,betaw,Cps,Cpw,Go,Ho,So,Aphi,diel,Gw,Sw,G]=RunNaClFortran(PTm)
%  [rhos,gam,phi,aw,AV,alpha,beta,Hr,ACp,rhow,alphas,alphaw,betas,betaw,Cps,Cpw,Go,Ho,So,Aphi,diel,Gw,Sw,G]

[pm,tm,mm]=ndgrid(PTm{1},PTm{2},PTm{3});
Pflg=0;
Tflg=0;
mflg=0;
nP=length(PTm{1});
nT=length(PTm{2});
nm=length(PTm{3});
if nP==1, Pflg=1;end
if nT==1, Tflg=1;end
if nm==1, mflg=1;end

TPm=[[tm(:) pm(:) mm(:)];-1 0 0];
R=8.3144;
omega=1000/18.0152;
MW=.058443;
Goo=-9.045;

save TPM_INPUT.TXT TPm -ascii

%    !./NaCl_SolOLD.macexe
!./a.out
    load NACL_ARCHER.DAT
    !rm  TPM_INPUT.TXT
    !rm NACL_ARCHER.DAT


% 1 T, K    
% 2 P, MPa   
% 3 M(mol. kg-1)  
% 4 sol.act.coeff.  
% 5 solv.act.coeff.  
% 6 solv.activity  
% 7 V/(cm3.mol-1)  
% 8 expans./(cm3.mol-1.K-1)  
% 9 compr./(cm3.mol-1.MPa-1)  
% 10 rel. enthalpy/(kJ.mol-1)  
% 11 Cp/(J.K-1.mol-1)  
% 12 Soln dens/(g.cm-3)  
% 13 Solv dens/(g.cm-3)  
% 14 Soln expans/(K-1)  
% 15 Solv expans/(K-1)  
% 16 Soln compres/(MPa-1)  
% 17 Solv compres/(MPa-1)  
% 18 Soln Cp/(J.K-1.mol-1)  
% 19 Solv Cp/(J.K-1.mol-1)  
% 20 G0-G0(Tr,pr)/kJ.mol-1  
% 21 H0-H0(Tr,pr)/kJ.mol-1
% 22 S0-S0(Tr,pr)/J.K-1.mol-1
% 23 Aphi
% 24 D
% 25 Gw
%26 Sw
Archer.gam=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,4),nP,nT,nm))));
Archer.phi=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,5),nP,nT,nm))));
Archer.aw=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,6),nP,nT,nm))));
Archer.AV=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,7),nP,nT,nm))));
Archer.alpha=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,8),nP,nT,nm))));
Archer.beta=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,9),nP,nT,nm))));
Archer.Hr=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,10),nP,nT,nm))));
Archer.ACp=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,11),nP,nT,nm))));
Archer.rhos=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,12),nP,nT,nm))));
Archer.rhow=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,13),nP,nT,nm))));
Archer.alphas=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,14),nP,nT,nm))));
Archer.alphaw=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,15),nP,nT,nm))));
Archer.betas=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,16),nP,nT,nm))));
Archer.betaw=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,17),nP,nT,nm))));
Archer.Cps=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,18),nP,nT,nm))));
Archer.Cpw=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,19),nP,nT,nm))));
Archer.Go=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,20),nP,nT,nm))));
Archer.Ho=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,21),nP,nT,nm))));
Archer.So=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,22),nP,nT,nm))));
Archer.Aphi=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,23),nP,nT,nm))));
Archer.Av=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,24),nP,nT,nm))));
Archer.Ac=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,25),nP,nT,nm))));
Archer.Ah=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,26),nP,nT,nm))));
Archer.diel=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,27,1),nP,nT,nm))));
Archer.Gw=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,28),nP,nT,nm))));
Archer.Sw=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,29),nP,nT,nm))));
%  Archer.diel=squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,24),nP,nT,nm))));
%  Archer.Gw=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,25),nP,nT,nm))));
%  Archer.Sw=1e3*squeeze(squeeze(squeeze(reshape(NACL_ARCHER(:,26),nP,nT,nm))));

% remove singletons from arrays 
if ((Pflg) && (Tflg) && (mflg))
    mm=squeeze(squeeze(squeeze(mm(1,1,1))));
    tm=squeeze(squeeze(squeeze(tm(1,1,1))));
elseif (not(Pflg) && (Tflg) && (mflg))
    mm=squeeze(squeeze(mm(:,1,1)));
    tm=squeeze(squeeze(tm(:,1,1)));
elseif (not(Pflg) && not(Tflg) && (mflg))
    mm=squeeze(squeeze(mm(:,:,1)));
    tm=squeeze(squeeze(tm(:,:,1)));
elseif ((Pflg) && not(Tflg) && not(mflg))
    mm=squeeze(squeeze(mm(1,:,:)));
    tm=squeeze(squeeze(tm(1,:,:)));
elseif (not(Pflg) && not(Tflg) && (mflg))
    mm=squeeze(squeeze(mm(:,:,1)));
    tm=squeeze(squeeze(tm(:,:,1)));
elseif (not(Pflg) && (Tflg) && not(mflg))
    mm=squeeze(squeeze(mm(:,1,:)));
    tm=squeeze(squeeze(tm(:,1,:)));
elseif ((Pflg) && (Tflg) && not(mflg))
    mm=squeeze(squeeze(mm(1,1,:)));
    tm=squeeze(squeeze(tm(1,1,:)));
end

% use definitions to calculate Gibbs energy from the parts
% log of water activity
lnaw=-mm.*Archer.phi*2/omega;

% G per kilogram of water
Archer.G= Archer.Gw + omega*R*tm.*lnaw + mm.*(Archer.Go +  R*2*tm.*log(eps+mm.*Archer.gam));

% also G per kilogram of solution
fac=((1+MW*mm)).^-1;
Archer.Gs=fac.*Archer.G;


