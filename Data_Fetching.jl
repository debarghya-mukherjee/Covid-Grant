function data_fetching(start, days, state, smoothing)
    n_days_collect = days
    date_start = Dates.Date(start[1],start[2],start[3])
    State_data_matrix = Array{Union{Missing, Float64}}(missing, n_days_collect, 5)
    for d in 1:n_days_collect
        date_now = date_start + Dates.Day(d)
        date_now = Dates.format(date_now, "mm-dd-yyyy")
        url = string("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports_us/", date_now, ".csv")
        res = HTTP.get(url)

        data_now = CSV.read(res.body);
        propertynames(data_now) # Give column names

        State_data = @where(data_now[:, [:Province_State, :Confirmed, :Active, :Recovered, :Deaths, :Hospitalization_Rate]], :Province_State .== state)
        State_data_matrix[d, :] = convert(Matrix, State_data[:, 2:end])
        println(d)
    end

    #CSV.write("MI_data.csv", DataFrame(State_data_matrix), writeheader=false)


    if smoothing
        kernel = OffsetArray(fill(1/7, 7), -3:3)
        smoothed_data = zeros(size(State_data_matrix, 1), 4)
        for i = 1:4
            smoothed_data[:, i] = imfilter(State_data_matrix[:, i], kernel)
        end
        CSV.write(string("/Users/",ENV["USER"],"/Box/Corona/Julia/Data/State_smoothed_data.csv"), DataFrame(smoothed_data), writeheader=false)
    else
        CSV.write(string("/Users/",ENV["USER"],"/Box/Corona/Julia/Data/State_data.csv"), DataFrame(State_data_matrix[:, 1:4]), writeheader=false)
    end
end
