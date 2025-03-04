function [rmse, den_sig, output_snr] = Multivariate_SSRC_rescaling(args)
    % Perform the initial rescaling SSRC operation
    [~, args] = Rescaling_SSRC(args);

    % Perform PCA on the predicted noise
    NoiseSet = args.PredictedNoise';
    [PCAaxis, args.Noise_set, args.PCAvar] = pca(NoiseSet);
    invPCA = inv(PCAaxis);
    
    % Transform the data using PCA
    args.data_gt = args.data_gt * PCAaxis;
    args.NoisyData = args.NoisyData * PCAaxis;
    args.prediction = args.prediction' * PCAaxis;
    
    % Calculate the variance of the predicted ground truth
    PredGt = args.prediction - args.Noise_set;
    args.PredGtVar = var(PredGt)';

    % Normalize the noisy data
    args.MaxNoisyData = max(args.NoisyData);
    args.MinNoisyData = min(args.NoisyData);
    args.NormalizedNoisyData = 2 * ((args.NoisyData - min(args.NoisyData)) ./ (max(args.NoisyData) - min(args.NoisyData)) - 0.5);

    % Store PCA transformations
    args.PCAaxis = PCAaxis;
    args.invPCA = invPCA;

    % Perform the selective multivariate SSRC operation after PCA
    [rmse, args] = Rescaling_SSRC(args);

    % Denoised signal after PCA-guided SSRC
    den_sig = args.prediction';

    % Define the ground truth and noisy signals for SNR calculation
    A = args.data_gt(args.initLen + 1:end, :);

    % Calculate SNR for each channel
    output_snr = snr(A,A-den_sig);
end
