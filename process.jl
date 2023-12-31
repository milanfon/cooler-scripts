using CSV
using DataFrames
using StringEncodings
using Dates
using Statistics
using Printf
using Plots

datetime_format = dateformat"d.m.y H:M:S.s";

columns_info = Dict(
    "Date" => String,
    "Time" => String,
    "CPU [RPM]" => Float64,
    "Takt jader (avg) [MHz]" => Float64,
    "CPU (Tctl/Tdie) [°C]" => Float64,
    "Pouzdro CPU (průměr) [°C]" => Float64
)

function filter_values(df, columns_info)
    filtered_data = Dict{String, Vector{Any}}()
    
    for (col_name, col_type) in columns_info
        filtered_data[col_name] = Vector{col_type}()
        for val in df[!, col_name]
            try
                if col_type == Float64
                    push!(filtered_data[col_name], parse(Float64, string(val)))
                elseif col_type == Int32
                    push!(filtered_data[col_name], parse(Int32, string(val)))
                else
                    push!(filtered_data[col_name], val)
                end
            catch e
                if isa(e, ArgumentError) || isa(e, MethodError)
                    continue
                else
                    rethrow(e)
                end
            end
        end
    end

    return filtered_data
end

function calculate_time_differences(datetimes::Vector{DateTime})
    n = length(datetimes)
    time_diffs = zeros(Float64, n)
    time_diffs[1] = 0.0  

    for i in 2:n
        diff = datetimes[i] - datetimes[i-1]
        time_diffs[i] = (Dates.value(diff) / 1000.0)  
    end

    return time_diffs
end

println("Loading file...")

open(ARGS[1], enc"WINDOWS-1250") do io
    df = CSV.File(io, select=collect(keys(columns_info))) |> DataFrame
#    first_col_name = names(df)[2]
#    col_names = names(df)
#    for (index, name) in enumerate(col_names)
#        println("$(index). $name")
#    end
    filtered_data = filter_values(df, columns_info)

    datetime_strings = ["$(filtered_data["Date"][i]) $(filtered_data["Time"][i])" for i in 1:length(filtered_data["Date"])]
    datetimes = [DateTime(dt_str, datetime_format) for dt_str in datetime_strings[1:end-2]]
    
    time_diffs = calculate_time_differences(datetimes)

    print("Enter ambient temperature: ")
    ambient_temp = parse(Float64, readline())
    
#    for i in 1:length(filtered_time)
#        println("$(datetimes[i]) - $(filtered_power[i]) - Time Diff: $(time_diffs[i]) - $(filtered_memory[i])")
#    end

    # Mean calculation
    mean_data = Dict{String, Float64}()
    for (col_name, col_type) in columns_info
        if col_type in [Float64, Int32]
            mean_data[col_name] = mean(filtered_data[col_name])
        end
    end
    
    print("Start time: $(datetimes[1])\nEnd time: $(last(datetimes))\n")
    @printf "Average FAN CPU RPM: %0.2f\n" mean_data["CPU [RPM]"]
    @printf "Average clock: %0.2f\n" mean_data["Takt jader (avg) [MHz]"]
    @printf "Average Tctl/Tdie: %0.2f\n" mean_data["CPU (Tctl/Tdie) [°C]"] - ambient_temp
    @printf "Average Tcase: %0.2f\n" mean_data["Pouzdro CPU (průměr) [°C]"] - ambient_temp

    # Plots
    
    p = plot(datetimes, filtered_data["CPU (Tctl/Tdie) [°C]"] .- ambient_temp, label="Die temp", color=:blue,  ylims=(0, maximum(filtered_data["CPU (Tctl/Tdie) [°C]"])))
    hline!(p, [mean_data["CPU (Tctl/Tdie) [°C]"] .- ambient_temp], label="Die temp mean", color=:blue, linestyle=:dot)

    p_c = plot(datetimes, filtered_data["Takt jader (avg) [MHz]"], label="Clock", color=:orange,  ylims=(0, maximum(filtered_data["Takt jader (avg) [MHz]"])))
    hline!(p_c, [mean_data["Takt jader (avg) [MHz]"]], label="Clock mean", color=:orange, linestyle=:dot)

    p_f = plot(datetimes, filtered_data["CPU [RPM]"], label="Fan RPM", color=:red, ylims=(0, maximum(filtered_data["CPU [RPM]"])))
    hline!(p_f, [mean_data["CPU [RPM]"]], label="Fan RPM mean", color=:red, linestyle=:dot)

    combined_plot = plot(p, p_c, p_f, layout=(3,1), size=(1000, 500))
    display(combined_plot)

    readline()
end
