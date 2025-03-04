function [rmse, args] = Multi_SSRC(args)
fields = fieldnames(args);
for i = 1:length(fields)
    fieldName = fields{i};
    eval([fieldName ' = args.' fieldName ';']);
end

%% Give names to each values of hyperpara_set & task_spec_parms
if strcmp(opt_process,'R1')
    [a,resSize,reg,Win_scale,sparsity_factor,eig_rho] = opt_process_loader(hyparams,optimizer);
else
    folderName = sprintf('results/optimization/%s', args.optimizer);
    fileName = sprintf('%s_R1_%s_%s_%s_SNR%d_len%d.mat', args.optimizer, args.DataSystem, args.NoiseDistribution, args.NoiseMethod, args.AverageSnr, args.data_length);
    folderfile = (fullfile(folderName, fileName));

    if exist(folderfile, 'file')
        load(folderfile,'opt_result');
        [a, resSize, reg, sparsity_factor, Win_scale, eig_rho] = hyperparameter_loader(opt_result,args.optimizer);
    else
        fprintf('there is no opt-file, data : %s \n', DataSystem)
        a=0.6; resSize=200; reg=1e-8; sparsity_factor=0.8; Win_scale=1; eig_rho=0.3;
    end

end
%% Define the function
rng((now*1000-floor(now*1000))*100000)

inSize = min(size(data_gt));
delay = 1;

processCompleted = false;
while ~processCompleted
    Win = (rand(resSize,inSize+1)-0.5) .* Win_scale;

    W = sprandsym(resSize, sparsity_factor);
    eig_D=eigs(W,1);
    if eig_D == 0
        eig_D = 1; eig_rho = 0; % this is the code to make function down
    end
    W=(eig_rho/(abs(eig_D))).*W;
    W=full(W);

    X = zeros(1+resSize,trainLen-initLen);
    Yt = NormalizedNoisyData(initLen+1:initLen+trainLen+valLen,:)';
    Yt_train = Yt(:,1:trainLen);
    Yt_val = Yt(:,trainLen+1:trainLen+valLen);
    Yt_gt_train = data_gt(initLen+1:initLen+trainLen,:)';
    Yt_gt_val = data_gt(initLen+trainLen+1:initLen+trainLen+valLen,:)';

    X = zeros(1+resSize,trainLen-initLen);
    x = zeros(resSize,1);
    for t = 1:initLen+trainLen+valLen-delay
        u = NormalizedNoisyData(t,:)';
        x = (1-a)*x + a*tanh( Win*[1;u] + W*x );
        if t > initLen-delay
            X(:,t-initLen+delay) = [1;x];
        end
    end

    X_train = X(:,1:trainLen);
    X_val = X(:,trainLen+1:end);


    Wout = ((X_train*X_train' + reg*eye(1+resSize)) \ (X_train*Yt_train'))';

    if isnan(Wout(1))
        fprintf('First component of Wout is NaN, restarting...\n');
    else
        processCompleted = true;
    end
end

predicted_train = Wout * X_train;
predicted_val = Wout * X_val;

prediction_train = ( ((predicted_train/2) + 0.5) .* (MaxNoisyData-MinNoisyData)' ) + MinNoisyData';
ScaledupYt_train = ( ((Yt_train/2) + 0.5) .* (MaxNoisyData-MinNoisyData)' ) + MinNoisyData';

prediction_val = ( ((predicted_val/2) + 0.5) .* (MaxNoisyData-MinNoisyData)' ) + MinNoisyData';
ScaledupYt_val = ( ((Yt_val/2) + 0.5) .* (MaxNoisyData-MinNoisyData)' ) + MinNoisyData';

prediction = [prediction_train, prediction_val];
ScaledupYt = [ScaledupYt_train, ScaledupYt_val];

args.PredictedNoise = ScaledupYt - prediction;
args.prediction = prediction;

rmse = sum(sum((prediction_val - ScaledupYt_val).^2)) / trainLen;

end