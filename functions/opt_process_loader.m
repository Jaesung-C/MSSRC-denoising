%% induce optimzation parameter values for bayesian & surrogate
function [a,resSize,reg,Win_scale,sparsity_factor,eig_rho] = opt_process_loader(hyparams, optimizer)
    a = hyparams(1);
    resSize = hyparams(2);
    reg = hyparams(3);
    sparsity_factor = hyparams(4);
    Win_scale = hyparams(5);
    eig_rho = hyparams(6);

end
