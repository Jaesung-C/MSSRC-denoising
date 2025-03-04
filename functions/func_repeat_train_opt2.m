function mean_rmse = func_repeat_train_opt2(hyparams,repeat_num,args)

[args] = data_set(args);
rmse_set = zeros(repeat_num,1); args.hyparams = hyparams;
for repeat_i = 1:repeat_num
    rng(repeat_i*20000 + (now*1000-floor(now*1000))*100000)
    [rmse_set(repeat_i), ~, ~] = Multivariate_SSRC_rescaling(args);    
end
mean_rmse = mean(sort(rmse_set));
end



