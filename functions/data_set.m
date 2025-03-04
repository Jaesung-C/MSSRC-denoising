function [args] = data_set(args)
fields = fieldnames(args);
for i = 1:length(fields)
    fieldName = fields{i};
    eval([fieldName ' = args.' fieldName ';']);
end

args.synthetic_data = data_loader(DataSystem);
args.data_gt = args.synthetic_data(initial_discard+1:initial_discard+data_length, :);
args.DataSize = min(size(args.data_gt));

rng('default')

args.NoisyData = Noise_induce(args);
args.MaxNoisyData = max(args.NoisyData);
args.MinNoisyData = min(args.NoisyData);
args.NormalizedNoisyData = 2*( (args.NoisyData-min(args.NoisyData)) ./ (max(args.NoisyData)-min(args.NoisyData)) -0.5 );
args.Noise_set = args.NoisyData-args.data_gt;

end