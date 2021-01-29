%-------------------------------------------------------------------------%
%   FENIX BESS control: 
%   The code determines the size of the battery needed for avoiding the
%   excess of the maximal power for a certain period of time. 
%
%   Date: 12/10/2020 at 15:00
%   Author: Sofiane Kichou          email: sofiane.kichou@cvut.cz
%-------------------------------------------------------------------------%
clc;clear;clf;close;
tic

load('Consumption.mat'); % already parsed table - faster

% from = '2019-03-11 00:00:00';
% to   = '2019-03-13 00:00:00';

from = '2019-03-7 00:00:00';
to   = '2020-07-28 00:00:00';

Data1= T(T.data_time>=datetime(from) & T.data_time<datetime(to)  ,:);
% data time_step
Timestep = 1; % (min)

% Grid specifications
P_Grid_Max = 500;  % Grid contracted power(kW)
Energy_Grid_Max = P_Grid_Max/4; % Grid max energy that can be taken during 1/4 hour (kWh)


P_PV = Data1{:,2}*0;   % (kW)
P_Grid = P_Grid_Max*ones(length(P_PV),1); %(kW)
P_Load = Data1{:,1};  %(kW)
Time = Data1.data_time;

Energy_PV   = P_PV*Timestep/60;    % (kWh)
Energy_Grid = P_Grid*Timestep/60;  % (kWh)
Energy_Load = P_Load*Timestep/60;  % (kWh)

eff = 0.94;  %charge/discharge efficiency



%% INIT

Balance = Energy_PV + Energy_Grid - Energy_Load;
%Balance= zeros(1, length(Time));
Deficit= zeros(1, length(Time));
Excess = zeros(1, length(Time));


%% CALCULATE


% first step
i = 1;
if Balance(i)==0
    Excess(i)=0;
    Deficit(i)=0;
elseif Balance(i)<0
    Deficit(i)= (Balance(i)/eff);
    Excess(i)=0;
else
    Excess(i) = Balance(i);
    Deficit(i) = 0;
end


% compute loop
for i=2:length(Time)
%     Balance(i)=Energy_PV(i)+Energy_Grid(i)-Energy_Load(i);

    if Balance(i)<0
        Deficit(i)=Deficit(i-1)+(Balance(i)/eff);
        Excess(i)=0;
    elseif Balance(i)>=0 && (Deficit(i-1)+Balance(i)*eff)>=0
        Deficit(i)=0;
        Excess(i)= Deficit(i-1)+Balance(i)*eff;
    elseif Balance(i)>=0 && (Deficit(i-1)+Balance(i)*eff)<0
        Deficit(i)=Deficit(i-1)+Balance(i)*eff;
        Excess(i)=0;
    end 

end



%% SUM up results
Daily_excess = sum(Excess)
Max_deficit = max(abs(Deficit))
Battery_size = Max_deficit*20/100+Max_deficit   %including 80% of DOD
Total_consumption = sum(Energy_Load)



%% PLOT results
figure(1)
subplot(2,1,1)
plot(Time,Deficit,'r')
hold on 
plot(Time,Excess,'bo')
grid on
ylabel('Balance (kWh)')
xlabel('Time')
legend('Deficit','Excess');

subplot(2,1,2)
plot(Time,P_PV)
hold on 
plot(Time,P_Grid)
plot(Time,P_Load)
legend('PV','Grid','Load');

toc


