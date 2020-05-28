using Plots, Distributions, Random, Statistics, JLD, CSV
using Pkg, HTTP, DataFrames, Query, DataFramesMeta, Dates, ImageFiltering,OffsetArrays
Random.seed!(1);

# include("/Users/mdeb/Box/Corona/Julia/New_Functions/Data_Fetching.jl")
# include("/Users/mdeb/Box/Corona/Julia/New_Functions/Get_Testing_Rate.jl")
# include("/Users/mdeb/Box/Corona/Julia/New_Functions/Evolve.jl")
# include("/Users/mdeb/Box/Corona/Julia/New_Functions/LS_Optimization.jl")
user = ENV["USER"]
include(string("/Users/",user,"/Box/Corona/Julia/Github_Repository/Covid-Grant/Data_Fetching.jl"))
include(string("/Users/",user,"/Box/Corona/Julia/Github_Repository/Covid-Grant/Get_Testing_Rate.jl"))
include(string("/Users/",user,"/Box/Corona/Julia/Github_Repository/Covid-Grant/Evolve.jl"))
include(string("/Users/",user,"/Box/Corona/Julia/Github_Repository/Covid-Grant/LS_Optimization.jl"))


#--- Define necessary variables

n_days = 50
real_data_days = 25


#--- Fetching and loading real data

data_fetching([2020, 4, 30], real_data_days, "Michigan", true)
real_data = CSV.read(string("/Users/",user,"/Box/Corona/Julia/Data/State_smoothed_data.csv"), header=false)
real_data = convert(Matrix, real_data[:,1:4])


#--- Get testing rate

df = CSV.read(string("/Users/mdeb/Box/Corona/Julia/Data/testing_data_26.csv"))
T = size(df,1)

for r in 2:5    #Convert entries from string to Float64
    df[!,r] = parse.(Float64, replace.(replace.(df[!,r], "%"=>""), ","=>""))
end
positive_test = df[53:77, 2]
n_days_now = length(positive_test)

n_counties = 1
N = [Int(1e7)]
Init = [trunc(Int, real_data[1,2] * 0.9)  trunc(Int, real_data[1,2] * 0.1) trunc(Int, real_data[1, 3]) trunc(Int, real_data[1, 4])]


cost_of_lockdown = 32 .* N ./ 1e6  # 4 × Avg. hourly wage × no. of people in county
gamma = 0.5
#med_sys_cap = 1000 .* N ./ 1e6
med_sys_cap = ones(n_counties) .* 1e13
overcap_cost = 3
cost_life = 6


μ = 20
μ_L = μ / 4;


α = zeros(6)
α[1] = 1  #L→I_m
α[2] = 0.017 #I_m→I_s
α[3] = 0.024 #I_m→R
α[4] = 0.012 #I_s→R
α[5] = 0.009 #I_s→D

R0 = 0.85


p_test_m, p_test_s = testing_rate_update(Init, N, α, R0, positive_test, n_days_now)

if length(p_test_m) < n_days
    p_test_m = [p_test_m; maximum(p_test_m)*ones(n_days - length(p_test_m))]
    p_test_s = [p_test_s; maximum(p_test_s)*ones(n_days - length(p_test_s))]
end

#--- Optimize parameters

grid_l = 10
R_range = [0.72:0.02:0.9;]
prob_range = exp.(range(-3,stop=-1,length=grid_l))
param_matrix = vec(collect(Iterators.product(prob_range,prob_range,
                                            prob_range,prob_range,R_range)))


α_opt, R0_opt = ls_optimization(param_matrix, 10)

#--- Optimize policy





#--- Plot the predictions

X_real_opt, X_obs_opt, _,_ = evolve(Init, N, α_opt, R0_opt, p_test_m, p_test_s)
plot(X_obs_opt[:,1,4], label="Simulated obs. deaths", legend=:bottomright)
plot!(real_data[:, 4], label="Real deaths")


plot(X_obs_opt[:, 1, 1] .+ X_obs_opt[:,1,2], label="obs. infected")
plot!(real_data[:, 2], label="active cases")


plot(X_obs_opt[:, 1, 3], label="obs recovered")
plot!(real_data[:, 3], label="real recovered")


plot(X_real_opt[:,1,3] + X_real_opt[:,1,4])
