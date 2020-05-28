function ls_optimization(param_matrix, n_reps = 10)
    batch_n = size(param_matrix, 1)
    Loss = ones((batch_n, n_reps)) .* Inf
    avg_loss = ones(batch_n) .* Inf
    # Current_job = parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
    Current_job = 1

    lb = batch_n * (Current_job - 1) + 1
    ub = batch_n * Current_job
    global count = 1
    for outer_loop in lb:ub
        pn = [1;
         param_matrix[outer_loop][1];
         param_matrix[outer_loop][2];
         param_matrix[outer_loop][3];
         param_matrix[outer_loop][4];]
        for rep in 1:n_reps
            X_obs = evolve(Init, N, pn, param_matrix[outer_loop][5], p_test_m, p_test_s)[2]
            Loss[count, rep] = sqrt((1*mean((X_obs[1:25,1,1] + X_obs[1:25,1,2] - real_data[1:25,2]).^2) +
                            1 * mean((X_obs[1:25,1,3] - real_data[1:25,3]).^2) +
                            1 * mean((X_obs[1:25,1,4] - real_data[1:25,4]).^2)))

        end
        avg_loss[count] = mean(Loss[count,:])
        global count = count + 1
    end

    opt_ind = argmin(avg_loss)
    opt_alpha = ones(5)
    opt_alpha[2] = param_matrix[opt_ind][1]
    opt_alpha[3] = param_matrix[opt_ind][2]
    opt_alpha[4] = param_matrix[opt_ind][3]
    opt_alpha[5] = param_matrix[opt_ind][4]
    opt_R0 = param_matrix[opt_ind][5]
    return (opt_alpha, opt_R0, opt_ind, avg_loss[opt_ind])

end
