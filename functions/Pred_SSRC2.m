function [rmse, args , GivenMean, TrueMean] = Pred_SSRC2(args, MachineSnr)
fields = fieldnames(args);
for i = 1:length(fields)
    fieldName = fields{i};
    eval([fieldName ' = args.' fieldName ';']);
end

%% Give names to each values of hyperpara_set & task_spec_parms
if strcmp(opt_process,'R2')
    [a,resSize,reg,Win_scale,sparsity_factor,eig_rho] = opt_process_loader(hyparams,optimizer);
else
    folderName = sprintf('results/optimization/%s', args.optimizer);
    fileName = sprintf('%s_R2_%s_%s_%s_SNR%d_len%d.mat', args.optimizer, args.DataSystem, args.NoiseDistribution, args.NoiseMethod, args.AverageSnr, args.data_length);
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
    Yt_gt = [Yt_gt_train, Yt_gt_val];

    %maxMachineSnr = max(MachineSnr);
    x = zeros(resSize,1);
    for t = 1:initLen+trainLen+valLen-delay
        u = NormalizedNoisyData(t,:)';
        ratio = PCAvar./PredGtVar;
        u = u./(1+ratio);

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

if exist('PCAaxis')
    args.prediction = args.invPCA'*prediction;
    args.prediction_val = args.invPCA'*prediction_val;
    args.PredictedNoise = args.invPCA'*(ScaledupYt - prediction);
    args.ScaledupYt = args.invPCA'*ScaledupYt;
    args.ScaledupYt_val = args.invPCA'*ScaledupYt_val;
    args.Yt_gt = args.invPCA'*Yt_gt;
    args.data_gt = args.data_gt * args.invPCA;
    args.NoisyData = args.NoisyData * args.invPCA;
else
    args.prediction = prediction;
    args.PredictedNoise = ScaledupYt - prediction;
    args.ScaledupYt = ScaledupYt;
    args.Yt_gt = Yt_gt;
end

rmse = sum(sum((args.prediction_val - args.ScaledupYt_val).^2)) / trainLen;

TrueError = sqrt( sum((args.prediction - args.Yt_gt).^2,2) ./ sum((args.Yt_gt).^2,2) );
GivenError = sqrt( sum((args.prediction - args.ScaledupYt).^2,2) ./ sum((args.ScaledupYt).^2,2) );
TrueMean = mean(TrueError);
GivenMean = mean(GivenError);
end