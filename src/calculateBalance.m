function [ TIME, SUMS ] = calculateBalance( DATA, timestep, Pmax, interval, eff, max_window )
%FINDBESSSIZE Determines the size of the battery needed for avoiding the
%   excess of the maximal power for a certain period of time.

%   DATA = input data contains load and time vector
%   timestep = input data time step
%   Grid = grid parameters
%   Batt = intended battery parameters
%   max_window = upper limit to cover consecutive days with battery
%   max_window == 0 to calculate just E_balance

%   TIME = centers of time intervals
%   SUMS = sumus all possible lengths of E_balance up to max_window
%   SUMS_max = maximum of sums (array for all sums lengths maximums)
%   Batt.cap = capacity to cover peaks in all intervals inc. DOD
%   Batt.cap_idx = index of bat. capacity inside SUMS_max = length of 

%   author = sofiane.kichou@cvut.cz
%   author = vladislav.martinek@cvut.cz


    if nargin < 2
        % data time_step
        timestep = duration(0,1,0); % 1 minute
    end
    
    if nargin < 3
        % Grid specifications
        Pmax = 500;  % Grid contracted power(kW)
%         Energy_Grid_Max = P_Grid_Max/4; % Grid max energy that can be taken during 1/4 hour (kWh)
    end
    
    if nargin < 4
        interval = duration(0,15,0);
    end
    
    if nargin < 5
        eff = 1; %calculate just energy
    end
    
    if nargin < 6
        max_window = 1; %calculate only energy balance (1 sample window
    else
        max_window = max_window  * ( duration(24,0,0) / interval );
    end
    
    
    
    
    %% INIT    
    samples = interval / timestep; % number of samples per interval
    
    % reshape according to ratio of Grid measurement interval and timestep
%     LOAD = LOAD(1) : LOAD(  ); % cut to modulo samples
    LOAD = reshape(DATA.load, samples, [])';    

    TIME = reshape(DATA.time, samples, [])';
    TIME = TIME(:, ceil(samples/2) ); %center of interval

    
    %% CALCULATE
    % Energy is calculated for every interval
    % Energy = P * time = load * 1/4 [kWh]
    E_LOAD = mean(LOAD,2) * ( interval / duration(1,0,0) );

    % P max from grid integrated for intervals
    E_GRID = repmat( ( interval / duration(1,0,0) ) * Pmax, length(E_LOAD), 1 );

    % energy balance based on load and grid energy maximum
    E_BALANCE = E_LOAD - E_GRID;
    
    % efficiency influence
    E_BALANCE(E_BALANCE>0) = E_BALANCE(E_BALANCE>0) * 1/eff; %discharging
    E_BALANCE(E_BALANCE<0) = E_BALANCE(E_BALANCE<0) * eff; %charging


    % calculate capacities needed to cover E_balance = M
    SUMS = zeros( length(E_BALANCE), max_window);
    SUMS(:,1) = E_BALANCE; % sums of length=1 is the original E_balance
    % calculate M for all lengths of sum up to max_window
    for w = 2 : max_window
        SUMS(:,w) = movsum( E_BALANCE, w );
    end


end

