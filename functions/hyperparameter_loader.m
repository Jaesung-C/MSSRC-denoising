function [a, resSize, reg, sparsity_factor, Win_scale, eig_rho] = hyperparameter_loader(opt_value, optimizer)

    a = opt_value(1);
    resSize = opt_value(2);
    reg = opt_value(3);
    sparsity_factor = opt_value(4);
    Win_scale = opt_value(5);
    eig_rho = opt_value(6);
end