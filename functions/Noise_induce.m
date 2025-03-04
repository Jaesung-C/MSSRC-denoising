function NoisyData = Noise_induce(args)
% Add noise to data_gt based on provided parameters
% Unpack fields from args
fields = fieldnames(args);
for i = 1:length(fields)
 fieldName = fields{i};
 eval([fieldName ' = args.' fieldName ';']);
end
if strcmp(NoiseMethod, 'additive_correlated')
if strcmp(NoiseDistribution, 'gaussian')
 mu = zeros(DataSize, 1);
 G = randn(DataSize, DataSize);
 sigma = G' * G;
 ns = size(data_gt, 1);
 noise = mvnrnd(mu, sigma, ns);
 normsig = norm(data_gt, 'fro')^2;
 signal_power = normsig / numel(data_gt);
 desired_snr_linear = 10^(AverageSnr / 10);
 noise_power = signal_power / desired_snr_linear;
 scaling_factor = sqrt(noise_power / var(noise(:)));
 noise = noise * scaling_factor;
 NoisyData = data_gt + noise;
else
 error('Unknown noise distribution: %s', NoiseDistribution);
end
elseif strcmp(NoiseMethod, 'random_axis')
 [ns, dim] = size(data_gt);
 num_random_axes = 7;
 R = randn(dim, num_random_axes);
 R = R ./ vecnorm(R);

switch NoiseDistribution
case 'impulse'
% Generate impulse noise based on Additive Outlier (AO) model
% y(n) = x(n) + v(n), where v(n) = z(n)i(n)
 noise = zeros(ns, num_random_axes);
 impulse_prob = 0.1; % Probability of impulse occurrence (ε)
for i = 1:num_random_axes
% Generate Bernoulli switching sequence z(n),
% P(z(n)=1) = ε, P(z(n)=0) = 1-ε
 impulse_locs = rand(ns, 1) < impulse_prob;
% Generate impulse values i(n) from uniform distribution
 noise(impulse_locs, i) = rand(sum(impulse_locs), 1);
end
case 'poisson'
 % Generate random lambda values for each axis
 noise = zeros(ns, num_random_axes);
 for i = 1:num_random_axes
     lambda_i = 1 + 9*rand();
     noise(:,i) = poissrnd(lambda_i, ns, 1);
 end
case 'weibull'
 % Generate different parameters for each axis
 noise = zeros(ns, num_random_axes);
 for i = 1:num_random_axes
     % Vary scale and shape slightly for each axis
     noise(:,i) = wblrnd(1+rand(), 10*rand(), ns, 1);
 end
end

% Add random sign flips with 50% probability for all noise distributions
random_signs = sign(rand(size(noise)) - 0.5);  % Generate +1 or -1 with 50% probability each
noise = noise .* random_signs;  % Apply random signs to the noise

 noise_in_original_space = noise * R';
% Scale noise to achieve desired SNR
 normsig = norm(data_gt, 'fro')^2;
 signal_power = normsig / numel(data_gt);
 desired_snr_linear = 10^(AverageSnr / 10);
 noise_power = signal_power / var(noise_in_original_space(:));
 scaling_factor = sqrt(noise_power / desired_snr_linear);
 scaled_noise = noise_in_original_space * scaling_factor;
 NoisyData = data_gt + scaled_noise;
else
 error('Unknown noise method: %s', NoiseMethod);
end
end