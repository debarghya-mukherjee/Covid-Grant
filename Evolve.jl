function randomize(p)
    return p
end

function evolve(Initial_val_obs, N, α, R0, p_test_m, p_test_s)
    days_total = 1/(α[2] + α[3])
    #days_total = 7
    prob_SL = zeros((n_days, n_counties)) # Mild, Severe, Recovered, Death
    X = zeros(Int64, (n_days, n_counties, 6)) # Susceptible, Latent, Mild, Severe, Recovered, Death
    X_obs = zeros(Int64, (n_days, n_counties, 4))

    X_obs[1, 1, :] = Initial_val_obs

    X[1, :, 4:5] .= trunc.(Int, 1.5 * X_obs[1, :, 2:3])
    X[1, :, 3] .= trunc.(Int, 2 * X_obs[1, :, 1])
    X[1, :, 6] .= 3 * X_obs[1, :, 4]
    X[1, :, 2] .= 1
    X[1, :, 1] .=  Int(N[1] - sum(X[1, 1, 2:6]))


    lockdown = falses(n_counties)
    p_sl = zeros(n_counties)

    new_mild_cases = zeros((n_days - 1, n_counties))
    new_severe_cases = zeros((n_days - 1, n_counties))
    new_cases = zeros((n_days - 1, n_counties))



    for t in 2:n_days
        for s in 1:n_counties
            if t < 200
                lockdown[s] = true
            else
                lockdown[s] = false
            end

            I_now = X[t-1, 1, 3] / N[1]
            S_now = X[t-1, 1, 1] / N[1]

            if lockdown[s]
                p_sl[s] = 1 - exp(-(R0/days_total) * I_now * S_now)
                p_sl[s] = max(min(p_sl[s], 1),0)
                prob_SL[t,s] = p_sl[s]
            else
                p_sl[s] = 1 - exp(-((R0+0.7)/days_total) * I_now * S_now)
                p_sl[s] = max(min(p_sl[s], 1),0)
                prob_SL[t,s] = p_sl[s]
            end
            n_SL = rand(Binomial(X[t-1,s,1], randomize(p_sl[s]))) # Number of S → L
            X[t, s, 1] = X[t-1, s, 1] - n_SL

            n_LI = rand(Binomial(X[t-1, s, 2], (α[1])))
            X[t, s, 2] = X[t-1, s, 2] + n_SL - n_LI

            n_ImIs, n_ImR, n_ImIm = rand(Multinomial(X[t-1, s, 3], [α[2], α[3], 1-α[2]-α[3]]))
            X[t, s, 3] = X[t-1, s, 3] + n_LI - n_ImIs - n_ImR


            if X[t,s,4] <= med_sys_cap[s]
                n_IsR, n_IsD, n_IsIs = rand(Multinomial(X[t-1, s, 4], [α[4], α[5], 1-α[4]-α[5]]))
            else
                n_IsR, n_IsD, n_IsIs = rand(Multinomial(X[t-1, s, 4], [α[4], α[6], 1-α[4]-α[6]]))
            end

            X[t, s, 4] = X[t-1, s, 4] + n_ImIs - n_IsR - n_IsD
            X[t, s, 5] = X[t-1, s, 5] + n_IsR + n_ImR
            X[t, s, 6] = X[t-1, s, 6] + n_IsD

            new_cases[t-1, s] = n_SL
            new_mild_cases[t - 1, s] = n_LI
            new_severe_cases[t - 1, s] = n_ImIs


            tested_mild = rand(Binomial(max(X[t, s, 3] - X_obs[t-1, s, 1], 0), p_test_m[t]))
            tested_severe = rand(Binomial(max(X[t, s, 4] - X_obs[t-1, s, 2], 0), p_test_s[t]))


            n_ImIs_o, n_ImR_o, n_ImIm_o = rand(Multinomial(X_obs[t-1, s, 1], [α[2], α[3], 1-α[2]-α[3]]))

            X_obs[t, s, 1] = X_obs[t-1, s, 1] - n_ImIs_o - n_ImR_o + tested_mild

            n_IsR_o, n_IsD_o, n_IsIs_o = rand(Multinomial(X_obs[t-1, s, 2], [α[4], α[5], 1-α[4]-α[5]]))

            X_obs[t, s, 2] = X_obs[t-1, s, 2] + n_ImIs_o - n_IsR_o - n_IsD_o + tested_severe
            X_obs[t, s, 3] = X_obs[t-1, s, 3] + n_IsR_o + n_ImR_o
            X_obs[t, s, 4] = X_obs[t-1, s, 4] + n_IsD_o

        end
    end
    return (X, X_obs, prob_SL, new_cases)
end
