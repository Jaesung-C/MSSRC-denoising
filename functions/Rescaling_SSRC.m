function [rmse, args] = Rescaling_SSRC(args)
fields = fieldnames(args);
for i = 1:length(fields)
    fieldName = fields{i};
    eval([fieldName ' = args.' fieldName ';']);
end

if ~exist('PCAaxis')
    [args] = data_set(args);
end

fields = fieldnames(args);
for i = 1:length(fields)
    fieldName = fields{i};
    eval([fieldName ' = args.' fieldName ';']);
end

if ~exist('PCAaxis','var')
    [rmse, args] = Multi_SSRC(args);
elseif exist('PCAaxis','var')
    MachineSnr = var(args.NoisyData)./args.PCAvar';
    [rmse, args , ~, ~] = Pred_SSRC2(args, MachineSnr);
end

end