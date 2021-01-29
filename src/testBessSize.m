function [ Time, I_L, I_PV, I_Gridf, I_Excessf, Penalf, Errorf, SOCf, I_Dischargef, ...
    I_Chargef, EE, Grid_Max_Energy, Z, t ] ...
    = testBessSize(  Data1, timestep, Batt, Grid)
%TESTBESSSIZE Control Strategy type: Peak shaving with a fix limit
%   Detailed explanation goes here



  
    if nargin < 2
        % data time_step
        timestep = 1; % (min)
    end


    Time    = Data1.time;      % Simulation time
    P_L     = Data1.load*1000; % CoBatt.nsumption (W)
    P_PV    = Data1.load*1000*0;   % Power from Roof PV (W)

    I_L  = P_L/Grid.VAC;   % current (A)
    I_PV = P_PV/Grid.VAC;

    %___Battery specificatioBatt.ns________________________________________________%
    if nargin < 3
        Batt.capacity = 500;%160; % (kWh)
        Batt.ns = 6*4;   % Number of cells 6*4*2V = 48Vdc
        Batt.V = 48;  % (V)
        Batt.SOCmax = Batt.capacity*1000/Grid.VAC*Batt.V;
        Batt.SOC_max = 1;
        Batt.SOC1 = 1;   % initial SOC (can be 0.5)
        Batt.SOC3 = 0.2; % 0.25; % Min. SOC of the battery.
        Batt.K = 0.95;    % Charging efficiency
        Batt.D = 1.9e-6;  % Self dis-charging rate (h^-1)
        Batt.SOC2 = Batt.SOC_max;

        Batt.I_dis_max = 3000; % Maximum discharge current [A]
        Batt.I_cha_max = 3000; % Maximum charge current [A]
    end
    
    %___Grid contracted power_________________________________________________%
    if nargin < 4
        Grid.Pmax = 500;  % Grid contracted power(kW)
        Grid.VAC = 230;
    end    
    I_Grid_max = Grid.Pmax/Grid.VAC;
    % I_Grid_security = 10*I_Grid_max;
    Grid_Max_Energy = Grid.Pmax/4; % Grid max energy that can be taken during 1/4 hour (kWh)

    %___Initialization________________________________________________________%
    SOCf        = zeros(1, length(Time));
    I_Loadf     = zeros(1, length(Time));
    I_Chargef   = zeros(1, length(Time));
    I_Dischargef = zeros(1, length(Time));
    I_Gridf     = zeros(1, length(Time));
    I_Excessf   = zeros(1, length(Time));
    Errorf      = zeros(1, length(Time));
    Penalf      = zeros(1, length(Time));
    I_net       = zeros(1, length(Time));
    MAX_ENR     = zeros(1, length(Time));
    t = timestep / 60; %simulation time step

    if Batt.SOC1 < Batt.SOC_max
        W = 1;
    else
        W = 0;
    end

    % Setting a counter
    a = 0;
    b = 0;
    % count = 5*nn+nn-1; %
    count = 15; %
    SOCi = Batt.SOC1;
    

    %__Run____________________________________________________________________%

for i=1:length(Time)
    I_net(i)=I_PV(i)-I_L(i);
    if I_net(i) >=0 && W == 0
        I_Loadi = I_L(i);
        I_Gridi = 0;
        I_Excess = I_net(i);
        I_Dischargei = 0;
        I_Chargei = 0;
        Errori = 0;
        Penali = 0;
    elseif I_net(i) >=0 && W == 1 && I_net(i)<= Batt.I_cha_max && i == 1
        I_Loadi = I_L(i);
        I_Gridi = 0;
        I_Excess = 0;
        I_Dischargei = 0;
        I_Chargei = I_net(i);
        Errori = 0;
        Penali = 0;
        SOCi = charge_BESS(Batt.SOC1,I_Chargei,t); % (charge mode)
    elseif I_net(i) >=0 && W == 1 && I_net(i)> Batt.I_cha_max && i == 1
        I_Loadi = I_L(i);
        I_Gridi = 0;
        I_Excess = I_net(i)-Batt.I_cha_max;
        I_Dischargei = 0;
        I_Chargei = Batt.I_cha_max;
        Errori = 0;
        Penali = 0;
        SOCi = charge_BESS(Batt.SOC1,I_Chargei,t); % (charge mode)
    elseif I_net(i) >=0 && W == 1 && I_net(i)<= Batt.I_cha_max
        I_Loadi = I_L(i);
        I_Gridi = 0;
        I_Excess = 0;
        I_Dischargei = 0;
        I_Chargei = I_net(i);
        Errori = 0;
        Penali = 0;
        SOCi = charge_BESS(SOCf(i-1),I_Chargei,t); % (charge mode)
    elseif I_net(i) >=0 && W == 1 && I_net(i)> Batt.I_cha_max
        I_Loadi = I_L(i);
        I_Gridi = 0;
        I_Excess = I_net(i)-Batt.I_cha_max;
        I_Dischargei = 0;
        I_Chargei = Batt.I_cha_max;
        Errori = 0;
        Penali = 0;
        SOCi = charge_BESS(SOCf(i-1),I_Chargei,t); % (charge mode)
    elseif I_net(i) < 0 && abs(I_net(i))> I_Grid_max
        if i == 1 && (abs(I_net(i))-I_Grid_max)<=Batt.I_dis_max
            I_Loadi = I_L(i);
            I_Gridi = I_Grid_max;
            I_Excess = 0;
            I_Dischargei = abs(I_Grid_max-abs(I_net(i)));
            I_Chargei = 0;
            Errori = 0;
            Penali = 0;
            SOCi = discharge_BESS(Batt.SOC1,I_Dischargei,t);% (discharge mode):
        elseif i == 1 && (abs(I_net(i))-I_Grid_max) > Batt.I_dis_max
            I_Loadi = I_L(i);
            I_Gridi = I_Grid_max;
            I_Excess = 0;
            I_Dischargei = Batt.I_dis_max;
            I_Chargei = 0;
            Errori = 1;
            Penali = abs(I_net(i))-I_Grid_max - Batt.I_dis_max;
            SOCi = discharge_BESS(Batt.SOC1,I_Dischargei,t);% (discharge mode):
        elseif SOCf(i-1)>Batt.SOC3 && (abs(I_net(i))-I_Grid_max)<=Batt.I_dis_max
            I_Loadi = I_L(i);
            I_Gridi = I_Grid_max;
            I_Excess = 0;
            I_Dischargei = abs(I_Grid_max-abs(I_net(i)));
            I_Chargei = 0;
            Errori = 0;
            Penali = 0;
            SOCi = discharge_BESS(SOCf(i-1),I_Dischargei,t);% (discharge mode):
        elseif SOCf(i-1)>Batt.SOC3 && (abs(I_net(i))-I_Grid_max) > Batt.I_dis_max
            I_Loadi = I_L(i);
            I_Gridi = I_Grid_max;
            I_Excess = 0;
            I_Dischargei = Batt.I_dis_max;
            I_Chargei = 0;
            Errori = 1;
            Penali = abs(I_net(i))-I_Grid_max - Batt.I_dis_max;
            SOCi = discharge_BESS(SOCf(i-1),I_Dischargei,t);% (discharge mode):
        elseif SOCf(i-1) <= Batt.SOC3
            I_Loadi = I_L(i);
            I_Gridi = I_Grid_max;
            I_Excess = 0;
            I_Dischargei = 0;
            I_Chargei = 0;
            Errori = 1;
            Penali = abs(I_net(i))-I_Grid_max;
        end
    elseif I_net(i) < 0 && abs(I_net(i))<= I_Grid_max
        if i == 1 && (I_Grid_max-abs(I_net(i)))<=Batt.I_cha_max
            I_Loadi = I_L(i);
            I_Gridi = I_Grid_max;
            I_Excess = 0;
            I_Dischargei = 0;
            I_Chargei = I_Grid_max-abs(I_net(i));
            Errori = 0;
            Penali = 0;
            SOCi = charge_BESS(Batt.SOC1,I_Chargei,t);% (charge mode):
        elseif i == 1 && (I_Grid_max-abs(I_net(i))) > Batt.I_cha_max
            I_Loadi = I_L(i);
            I_Gridi = Batt.I_cha_max+abs(I_net(i));
            I_Excess = 0;
            I_Dischargei = 0;
            I_Chargei = Batt.I_cha_max;
            Errori = 0;
            Penali = 0;
            SOCi = charge_BESS(Batt.SOC1,I_Chargei,t);% (charge mode):
        elseif SOCf(i-1)<Batt.SOC_max && (I_Grid_max-abs(I_net(i)))<=Batt.I_cha_max
            I_Loadi = I_L(i);
            I_Gridi = I_Grid_max;
            I_Excess = 0;
            I_Dischargei = 0;
            I_Chargei = I_Grid_max-abs(I_net(i));
            Errori = 0;
            Penali = 0;
            SOCi = charge_BESS(SOCf(i-1),I_Chargei,t);% (charge mode):
        elseif SOCf(i-1)<Batt.SOC_max && (I_Grid_max-abs(I_net(i))) > Batt.I_cha_max
            I_Loadi = I_L(i);
            I_Gridi = Batt.I_cha_max+abs(I_net(i));
            I_Excess = 0;
            I_Dischargei = 0;
            I_Chargei = Batt.I_cha_max;
            Errori = 0;
            Penali = 0;
            SOCi = charge_BESS(SOCf(i-1),I_Chargei,t);% (charge mode):
        elseif SOCf(i-1) >= Batt.SOC_max
            I_Loadi = I_L(i);
            I_Gridi = abs(I_net(i));
            I_Excess = 0;
            I_Dischargei = 0;
            I_Chargei = 0;
            Errori = 0;
            Penali = 0;
            SOCi = SOCf(i-1);
        end
    end
    if SOCi>= Batt.SOC_max
        SOCi=1;
        W=0;
    else
        W=1;
    end
    SOCf(i)=SOCi;
    I_Loadf(i)=I_Loadi;
    I_Chargef(i)=I_Chargei;
    I_Dischargef(i)=I_Dischargei;
    I_Gridf(i)=I_Gridi;
    I_Excessf(i)=I_Excess;
    Errorf(i)=Errori;
    Penalf(i)=Penali;
    
    %%%%%%% Testing 15 miBatt.ns intervals %%%%%%%
    Energy = (I_Gridf(i)+Penalf(i))*Grid.VAC*t;
    Energy_taken = Energy + a;
    a = Energy_taken;  
    EE(:,i) = Energy_taken;
    if Energy_taken > Grid_Max_Energy
        Z(i) = 1;
    else
        Z(i) = 0;
    end
    
    while i>count+b 
        Energy_taken=0;
        a=0;
        b=i-1;
    end
        
end


% Excess_energy=(((sum(I_Excessf)*t)*Grid.VAC)/1000);        % kWh
% Enrgy_Grid=((sum(I_Gridf)*t)*Grid.VAC)/1000;               % kWh
% Enrgy_penal =((sum(Penalf)*t)*Grid.VAC)/1000;              % kWh
% Enrgy_Discharge=((sum(I_Dischargef)*t)*Grid.VAC)/1000;     % kWh
% Enrgy_Charge=((sum(I_Chargef)*t)*Grid.VAC)/1000;           % kWh
% Enrgy_PV=((sum(I_PV)*t)*Grid.VAC)/1000;                    % kWh
% Enrgy_consumed=((sum(I_L)*t)*Grid.VAC)/1000; 
% Enrgy_consumed1 = Enrgy_PV+Enrgy_Discharge+Enrgy_Grid+Enrgy_penal...
%     -Excess_energy-Enrgy_Charge;

    %%


end

