function [ time_out, data_out, timestep ] = refine( time_in, data_in )
%REFINE Refine given timeserie to whole days and homogenous serie.

%   author = vladislav.martinek@cvut.cz

    % calculate timestep
%     time_in = datenum( time_in );
    % make differences and select median
    timestep = median( time_in - circshift(time_in, 1) );
    
    % round to whole days
    if floor( time_in(1) ) == time_in(1)
        start = floor( time_in(1) );
    else
        start = ceil( time_in(1) );
    end
    
    if ceil( time_in(end) ) == time_in(end) + timestep
        dest = time_in(end);
    else
        dest = floor( time_in(end) ) - timestep;
    end
    
    % create homogenous timeserie
    time_out = (start : timestep : dest)';
    
    %recalculate to new timeserie
    data_out = interp1( time_in, data_in, time_out );
    
end

