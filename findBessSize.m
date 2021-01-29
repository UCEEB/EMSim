function [ TIME, SUMS ] = findBessSize( DATA, timestep, Grid, max_window )
%FINDBESSSIZE Determines the size of the battery needed for avoiding the
%   excess of the maximal power for a certain period of time.

%   DATA = input data contains load and time vector
%   timestep = input data time step
%   Grid = grid parameters
%   Batt = intended battery parameters
%   max_window = upper limit to cover consecutive days with battery

%   TIME = centers of time intervals
%   SUMS = sumus all possible lengths of E_balance up to max_window
%   SUMS_max = maximum of sums (array for all sums lengths maximums)
%   Batt.cap = capacity to cover peaks in all intervals inc. DOD
%   Batt.cap_idx = index of bat. capacity inside SUMS_max = length of 

%   author = sofiane.kichou@cvut.cz
%   author = vladislav.martinek@cvut.cz


    if nargin < 2
        % data time_step
        timestep = 1/60; % [h]
    end
    
    if nargin < 3
        % Grid specifications
        Grid.P_max = 500;  % Grid contracted power(kW)
%         Energy_Grid_Max = P_Grid_Max/4; % Grid max energy that can be taken during 1/4 hour (kWh)
        Grid.interval = 1/4;
    end
    
    if nargin < 4
        max_window = 1;
    end

    
    
    %% INIT
    samples = Grid.interval / timestep; % number of samples per Grid.interval
    max_window = max_window * 24 / Grid.interval;
    
    TIME = DATA.data_time;
    % make time vector homogenous, round timevector at whole days 
    Time_num = ( floor(datenum(TIME(1))) : timestep/24 : ceil(datenum(TIME(end))) )';
    Time_num(end) = []; 

    P_load = DATA{:,1};  %(kW)
    % stretch and fill possible empty places
    P_load_num = interp1(datenum(TIME), P_load, Time_num);
    % reshape according to ratio of Grid measurement interval and timestep
    P_load_num = reshape(P_load_num, samples, [])';    

    TIME = datetime(Time_num, 'ConvertFrom', 'datenum');
    TIME = reshape(TIME, samples, [])';
    TIME = TIME(:, floor(samples/2) ); %center of interval

    
    %% CALCULATE
    % Energy is calculated for every interval
    % Energy = P * time = load * 1/4 [kWh]
    E_LOAD = sum(P_load_num,2) * Grid.interval / samples;

    % P max from grid integrated for intervals
    E_GRID = repmat( Grid.interval * Grid.P_max, length(E_LOAD), 1 );

    % Load - Grid_max
    E_BALANCE = E_LOAD - E_GRID;


    % calculate capacities needed to cover E_balance = M
    SUMS = zeros( length(E_BALANCE), max_window);
    SUMS(:,1) = E_BALANCE; % sums of length=1 is the original E_balance
    % calculate M for all lengths of sum up to max_window
    for w = 2 : max_window
        SUMS(:,w) = movsum( E_BALANCE, w );
    end


end

