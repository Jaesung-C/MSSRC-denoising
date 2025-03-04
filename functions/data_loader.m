function data_gt = data_loader(option)
% Load ground truth data based on the specified option

if strcmp(option, 'kuramoto_sivashinsky50')
    load('DATA_kuramoto_sivashinsky50','ut') % Load data variable 'ut'
    data_gt = ut';

elseif strcmp(option, 'high_frequency')
    rng(0)
    N = 100;
    D = 10; % Number of dimensions
    data_gt = zeros((N-1)*1000+1, D);
    for d = 1:D
        k = 0:(N-1)*1000;
        freq = 2 * pi / (N + 10*d*rand(1)); % Frequency changes with dimension
        data_gt(:, d) = ((-1).^k .* sin(freq * k));
    end

elseif strcmp(option, 'forest')
    % If "forest.mat" exists in the current folder, load it.
    % Otherwise, please add "forest.mat" to the data folder.
    if exist('forest.mat', 'file')
        load('forest.mat')
        given_data_selected = forest_data;
        data_max = max(given_data_selected);
        data_gt = given_data_selected ./ data_max;
    else
        error('File "forest.mat" not found. Please add the file to the data folder.');
    end
end
end
