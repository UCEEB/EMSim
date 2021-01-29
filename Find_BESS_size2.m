%-------------------------------------------------------------------------%
%   FENIX BESS control: 
%   The code determines the size of the battery needed for avoiding the
%   excess of the maximal power for a certain period of time. 
%
%   Date: 12/10/2020 at 15:00
%   Author: Sofiane Kichou          email: sofiane.kichou@cvut.cz
%-------------------------------------------------------------------------%
clc;clear;clf;close;


% data time_step
Timestep = 1/60; % [h]
Grid.interval = 1/4; % [h]
Grid.P_max = 500; % Grid contracted power [kW]
eff = 0.94;  % charge/discharge efficiency
DOD = 0.8; % depth of discharge

%% LOAD
load('Fenix2019-20.mat'); % already parsed table - faster
% from = '2019-03-11 00:00:00';
% to   = '2019-03-13 00:00:00';

% TBD ensure that only full days are selected 
from = '2019-03-8 00:00:00';
to   = '2020-07-28 00:00:00';

Data1= T(T.data_time>=datetime(from) & T.data_time<datetime(to)  ,:);
P_load = Data1{:,1};  %(kW)

% round timevector at whole days
Time = Data1.data_time;
Time_num = ( floor(datenum(Time(1))) : Timestep/24 : ceil(datenum(Time(end))) )';
Time_num(end) = [];
% stretch and fill possible empty places
P_load_num = interp1(datenum(Time), P_load, Time_num);
Time = datetime(Time_num, 'ConvertFrom', 'datenum');



%% INIT
ratio = Grid.interval / Timestep;
max_window = 7; % to cover consecutive days
max_window = max_window*24/Grid.interval;

% reshape according to ratio of Grid measurement interval and timestep
P_load_num = reshape(P_load_num, ratio, [])';
Time = reshape(Time, ratio, [])';
Time = Time(:, floor(ratio/2) ); %center of interval

% Energy is calculated inside interval - aproximation
% calculate Energy = P * time = Load*1/4
E_load = sum(P_load_num,2) * Grid.interval / ratio;

% P max from grid integrated for intervals
E_grid_max = repmat( Grid.interval * Grid.P_max, length(E_load), 1 );

% Load - Grid_max * dis/charging efficiency
E_balance = (E_load - E_grid_max) * 1/eff;

% plot energy balance
figure
bar(Time, E_balance);
%TBD plot together with original load, enlarge time to 15min steps (make
%slopes)



%% CALCULATE
tic
M = zeros( length(E_balance), max_window);
M(:,1) = E_balance;
for w = 2 : max_window
    M(:,w) = movsum( E_balance, w );
end

M_max = max(M);


battery_capacity = max(M_max);
battery_capacity_idx = find(M_max == battery_capacity);
battery_capacity = battery_capacity * (1+1-DOD) %battery capacity to cover all peaks

toc



%% PLOT premil. results
figure
plot(M_max);



% TBD show batery capacity usage during period
figure
plot(M(:,battery_capacity_idx))






%% SUM up results
% Daily_excess =sum(Excess)
% Max_deficit = max(abs(Deficit))
% Battery_size = Max_deficit*20/100+Max_deficit   %including 80% of DOD
% Total_consumption=sum(Energy_Load)



%% PLOT results
% figure(1)
% subplot(2,1,1)
% plot(Time,Deficit,'r')
% hold on 
% plot(Time,Excess,'bo')
% grid on
% ylabel('Balance (kWh)')
% xlabel('Time')
% legend('Deficit','Excess');
% 
% subplot(2,1,2)
% plot(Time,P_Grid)
% hold on 
% plot(Time,P_load)
% legend('PV','Grid','Load');



