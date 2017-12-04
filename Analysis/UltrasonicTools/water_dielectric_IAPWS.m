function epsilon=water_dielectric_IAPWS(rho,TK)
%function epsilon=water_dielectric_IAPWS(rho,TK)
%dielectric constant of water given rho(g/cc) and T(K)
%from IAPWS 1997 release
%for 238-273K at 1bar,
%273 to 323K, to ice VI or 1GPa, 
%and above 323K to 0.6 GPa
%extrapolates "smoothly" to 1.2GPa and 1200K
%
%rho=fzero(@(rho) diff_meas_IAPWS95_P(rho,PGPa,TK),rhoapprox);


rho=rho(:)';
rmol=rho/18.015268e-6; %mol/m^3
r=rho/322e-3;
t=647.096/TK;

N=[ 0.978224486826
   -0.957771379375
    0.237511794148
    0.714692244396
   -0.298217036956
   -0.108863472196
    0.949327488264e-1
   -0.980469816509e-2
    0.165167634970e-4
    0.937359795772e-4
   -0.123179218720e-9];
N12=0.196096504426e-2;

I=[1 1 1 2 3 3 4 5 6 7 10]';
J=[0.25 1 2.5 1.5 1.5 2.5 2 2 5 0.5 10]';




g=1+sum((N.*t.^J).*(ones(11,1)*r).^(I*ones(size(r)))) + N12*r*(TK/228-1)^(-1.2);


A=6.0221367e23*6.138e-30^2*(4e-7*pi*299792458^2)/1.380658e-23/TK*g*rmol;
B=6.0221367e23*(4e-7*pi*299792458^2)*1.636e-40/3*rmol;
epsilon=(1+A+5*B+sqrt(9+2*A+18*B+A.^2+10*A.*B+9*B.^2))./(4-4*B)










