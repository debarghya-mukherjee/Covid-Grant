using Plots, Distributions, Random, Statistics, JLD, CSV
using Pkg, HTTP, DataFrames, Query, DataFramesMeta, Dates, ImageFiltering,OffsetArrays
Random.seed!(1);

# include("/Users/mdeb/Box/Corona/Julia/New_Functions/Data_Fetching.jl")
# include("/Users/mdeb/Box/Corona/Julia/New_Functions/Get_Testing_Rate.jl")
# include("/Users/mdeb/Box/Corona/Julia/New_Functions/Evolve.jl")
# include("/Users/mdeb/Box/Corona/Julia/New_Functions/LS_Optimization.jl")
user = ENV["USER"]
include(string("/Users/",user,"/Box/Corona/Julia/New_Functions/Data_Fetching.jl"))
include(string("/Users/",user,"/Box/Corona/Julia/New_Functions/Get_Testing_Rate.jl"))
include(string("/Users/",user,"/Box/Corona/Julia/New_Functions/Evolve.jl"))
include(string("/Users/",user,"/Box/Corona/Julia/New_Functions/LS_Optimization.jl"))


#--- Define necessary variables

n_days = 50
real_data_days = 25


#--- Fetching and loading real data

data_fetching([2020, 5, 1], real_data_days, "Michigan", true)
real_data = CSV.read(string("/Users/",user,"/Box/Corona/Julia/State_smoothed_data.csv"), header=false)
real_data = convert(Matrix, real_data[:,1:4])


#--- Get testing rate

df = CSV.read(string("/Users/",user,"/Box/Corona/Julia/Data/MIchigan_Test_Data_new.csv"))
T = size(df,1)

for r in 2:5    #Convert entries from string to Float64
    df[!,r] = parse.(Float64, replace.(replace.(df[!,r], "%"=>""), ","=>""))
end
positive_test = df[34:end, 2]
n_days_now = length(positive_test)

n_counties = 1
N = [Int(1e7)]
Init = [20000 3856 15659 4065]


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

R0 = 0.5


p_test_m, p_test_s = testing_rate_update(Init, N, α, R0, positive_test, n_days_now)

if length(p_test_m) < n_days
    p_test_m = [p_test_m; p_test_m[end]*ones(n_days - length(p_test_m))]
    p_test_s = [p_test_s; p_test_m[end]*ones(n_days - length(p_test_s))]
end

#--- Optimize parameters

X, X_obs, _, _ = evolve(Init, N, α, R0, p_test_m, p_test_s)
grid_l = 10
R_range = [0.05:0.05:0.5;]
prob_range = exp.(range(-3,stop=-1,length=grid_l))
param_matrix = vec(collect(Iterators.product(prob_range,prob_range,
                                            prob_range,prob_range,R_range)))


α_opt, R0_opt = ls_optimization(param_matrix, 10)

#--- Optimize policy





#--- Plot the predictions
