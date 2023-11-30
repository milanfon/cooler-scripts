using Plots

struct Cube
    dims::Tuple{Float64, Float64, Float64}
    color::Symbol
    name::String
end

function plot_cube!(plt, origin, cube::Cube)
    A, B, C = cube.dims
    x0, y0, z0 = origin

    vertices = [
        (x0, y0, z0), (x0 + A, y0, z0), (x0 + A, y0 + B, z0), (x0, y0 + B, z0), # Bottom vertices
        (x0, y0, z0 + C), (x0 + A, y0, z0 + C), (x0 + A, y0 + B, z0 + C), (x0, y0 + B, z0 + C)  # Top vertices
    ]
    edges = [
        (1, 2), (2, 3), (3, 4), (4, 1),
        (5, 6), (6, 7), (7, 8), (8, 5),
        (1, 5), (2, 6), (3, 7), (4, 8)
    ]
    
    added_label = false

    for edge in edges
        if !added_label
            plot!(plt, [vertices[edge[1]][1], vertices[edge[2]][1]], 
                       [vertices[edge[1]][2], vertices[edge[2]][2]], 
                       [vertices[edge[1]][3], vertices[edge[2]][3]], 
                       color=cube.color, label=cube.name)
            added_label = true
        else
            plot!(plt, [vertices[edge[1]][1], vertices[edge[2]][1]], 
                       [vertices[edge[1]][2], vertices[edge[2]][2]], 
                       [vertices[edge[1]][3], vertices[edge[2]][3]], 
                       color=cube.color, label="")
        end
    end
end

function plot_cubes(cubes::Vector{Cube})
    plt = plot(legend=:outertopright)

    for cube in cubes
        plot_cube!(plt, (0, 0, 0), cube) # Render every cube at 0 origin
    end

    display(plt)
end

cubes = [
    Cube((145, 136, 168), :red, "Dark Rock Pro 5"),
    Cube((161, 150, 165), :blue, "NH-D15"),
]

plot_cubes(cubes)
readline()
