clear; close all; clc;
addpath functions data;

%% Basic Settings
iter_max   = 10;   % Maximum number of function evaluations
repeat_num   = 20;     % Number of attempts per hyperparameter set

%% User Settings
args = struct();
args.DataSystem        = 'kuramoto_sivashinsky50';  % Data system (e.g., 'high_frequency', 'kuramoto_sivashinsky50')
args.AverageSnr        = 0;                % Average SNR value (e.g., 10, 0, -10)
args.data_length       = 3000;             % Data length (e.g., 2000, 10000, 40000)
args.NoiseDistribution = 'impulse';
args.NoiseMethod       = 'random_axis';

%% Default Settings
args.initial_discard   = 1000;              % Number of initial data points to discard
args.initLen           = 100;               % Initialization length
args.trainLen          = round((args.data_length - args.initLen) * 0.7); % Training data length
args.valLen            = args.data_length - args.initLen - args.trainLen;  % Validation data length
args.option_randval    = 'false';
args.optimizer         = 'surrogate';

%% Hyperparameter Boundaries for Optimization
% Order: [a, reservoir size, regularization, sparsity factor, Win_scale, eig_rho]
lb     = [0,   10,   1e-10, 0,   0.1, 0.1];
ub     = [1, 3000,       1, 1,   2.0, 2.5];
IntCon = 2; % Index of integer-constrained variable (reservoir size)

%% ===== Round 1 Optimization =====
args.opt_process = 'R1';  % Round identifier

rng('shuffle');  % Initialize random seed

tic;
options = optimoptions('surrogateopt', ...
    'MaxFunctionEvaluations', iter_max, ...
    'PlotFcn', 'surrogateoptplot', ...
    'UseParallel', false);
% Objective function for Round 1
func_R1 = @(x) func_repeat_train_opt1(x, repeat_num, args);
[opt_result, opt_fval_R1, opt_exitflag_R1, opt_output_R1, opt_trials_R1] = surrogateopt(func_R1, lb, ub, IntCon, options);
toc;

% Save Round 1 results
folderName = fullfile('results', 'optimization', args.optimizer);
if ~exist(folderName, 'dir')
    mkdir(folderName);
end
fileName_R1 = sprintf('surrogate_%s_%s_%s_%s_SNR%d_len%d.mat', args.opt_process, args.DataSystem, args.NoiseDistribution, args.NoiseMethod, args.AverageSnr, args.data_length);
save(fullfile(folderName, fileName_R1));

%% ===== Round 2 Optimization =====
args.opt_process = 'R2';  % Change round identifier

rng('shuffle');  % Reinitialize random seed

tic;
options = optimoptions('surrogateopt', ...
    'MaxFunctionEvaluations', iter_max, ...
    'PlotFcn', 'surrogateoptplot', ...
    'UseParallel', false);
% Objective function for Round 2
func_R2 = @(x) func_repeat_train_opt2(x, repeat_num, args);
[opt_result, opt_fval_R2, opt_exitflag_R2, opt_output_R2, opt_trials_R2] = surrogateopt(func_R2, lb, ub, IntCon, options);
toc;

% Save Round 2 results
fileName_R2 = sprintf('surrogate_%s_%s_%s_%s_SNR%d_len%d.mat', args.opt_process, args.DataSystem, args.NoiseDistribution, args.NoiseMethod, args.AverageSnr, args.data_length);
save(fullfile(folderName, fileName_R2));
