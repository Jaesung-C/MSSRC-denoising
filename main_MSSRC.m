clear; clc; close all;
addpath ./functions data;

%% User Settings
data_system = 'kuramoto_sivashinsky50';  % data options: ('kuramoto_sivashinsky50', 'high_frequency')
dataLen     = 10000;                      % data length (2000 / 10000 / 20000)
snr_val     = -10;                        % SNR value (-10 / 0 / 10)
args.NoiseDistribution = 'impulse'; % 'gaussian' 'impulse' 'weibull' 'poisson'
args.NoiseMethod       = 'random_axis'; % 'additive_correlated' 'random_axis'

%% Default Settings
args.initial_discard = 1000;
args.initLen         = 100;
args.optimizer       = 'surrogate';
args.opt_process     = 'off';
args.valLen          = 0;
args.data_length     = dataLen;
args.DataSystem      = data_system;
args.trainLen        = args.data_length - args.initLen;
args.AverageSnr      = snr_val;

%% Generate Data
args = data_set(args);
xgt = args.data_gt;
xn  = args.NoisyData;

%% Calculate SNR of Noisy Data
snr_noisy = snr(xgt,xn-xgt);

%% Apply MSSRC (SSRC) Method
[~, y_ssrc, avg_snr_ssrc] = Multivariate_SSRC_rescaling(args);

%% Display SNR Results
fprintf('Noisy Data SNR: %.2f dB\n', snr_noisy);
fprintf('MSSRC Denoised Data SNR: %.2f dB\n', avg_snr_ssrc);

%% Plot Results
figure;
figure_index = [3, 10, 17];
time_range = args.initLen+1 : args.initLen+1000;
xlim_val = [500 900];

for k = 1:length(figure_index)
    idx = figure_index(k);
    subplot(3, 1, k);
    plot(xn(time_range, idx), 'LineWidth', 1.5); hold on;
    plot(xgt(time_range, idx), 'LineWidth', 1.5);
    plot(y_ssrc(1:1000, idx), 'LineWidth', 1.5);
    title(sprintf('Variable %d', idx));
    ylabel('Value');
    xlabel('Time');
    legend('Noisy Data', 'Ground Truth', 'Processed (y_{ssrc})', 'Location', 'east');
    grid on;
    xlim(xlim_val);
    ylim([1.7*min(xgt(:,idx)), 1.7*max(xgt(:,idx))])
end
