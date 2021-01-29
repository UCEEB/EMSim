%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       BESS Discharging mode
%
% Inputs: 
%       SOCf_prev: SOC at time t-1 (SOCf(i-1)).
%       I_charge: Discharging current [A]
%       t: Sampling time [s]
% Outputs: 
%       SOCi: Actual SOC of the Battery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SOCi = discharge_BESS(SOCf_prev,I_discharge,t)
params;

B=SOC2;
V1=(1.926+.124*B)*ns;

syms v;
ee= double(int((V1/K*I_discharge-D*SOC2*SOCmax),v,0,t));

SOC=SOC_max+SOCmax^-1*ee;
SOC2=double(SOC);

SOCi = SOCf_prev-abs((SOC_max-SOC2));

