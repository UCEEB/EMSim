%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       BESS Charging mode
%
% Inputs: 
%       SOCf_prev: SOC at time t-1 (SOCf(i-1).
%       I_charge: Charging current [A]
%       t: Sampling time [s]
% Outputs: 
%       SOCi: Actual SOC of the Battery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SOCi = charge_BESS(SOCf_prev,I_charge,t)
params;

B=SOC2;
V1= (2+.148*B)*ns;

syms v;
ee= double(int((K*V1*I_charge-D*SOC2*SOCmax),v,0,t));

SOC=SOC_max+SOCmax^-1*ee;
SOC2=double(SOC);

SOCi = SOCf_prev+abs((SOC_max-SOC2));

