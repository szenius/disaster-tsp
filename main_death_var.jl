using JuMP, Gurobi, Distances, Plots

# debug stuff
debug = true
debug_N = 12

# p(new info coming in at each node)
new_info_prob = 0.4

# filenames
results_filename = string("./results/results", Dates.format(now(),
    "yymmddHHMM"), ".txt")
filename = "LocationFinal2.txt"

# parameters for saved tours
tour_filename = "LocationN12.txt" # format is like data input file, except the
                                  #    lines are in order of the generated tour
tour_result_filename = "LocationN12_result.txt" # tlapsed dead from the saved tour
tour_exists = true # true if you want to read from the two files above and
                   #    skip the first tsp generation

################################
# generate a tsp, or if there is a saved tour, just read that
# returns tlapsed, cycle_idx, dead
################################
function generate_tsp(N, c_pos, death, cost, ppl, curr_tlapsed, first_run)
    if tour_exists && first_run
        # we have saved the tour for this N in a data file
        # just read from this data file, don't need to generate tsp again
        return read_and_parse_tour_data(N)
    else
        # Solve initial assignment problem
        (m, x, tlapsed, dead) = solve_opt(N, c_pos, death, cost, ppl, curr_tlapsed)

        # Write results into file
        open(results_filename, "a") do f
            write(f, string("Generated TSP with objective value ",
                getobjectivevalue(m), " [", count, "]\n"))
        end
        return getvalue(tlapsed), plot_tour(x, c_pos, N), getvalue(dead)
    end
end

##############################
# plot tour
# return cycle_idx
##############################
function plot_tour(x, c_pos, N)
    x_final = getvalue(x)
    cycle_idx = Array{Int}(0)
    push!(cycle_idx, 1)
    while true
        v, idx = findmax(x_final[f=cycle_idx[end],t=1:N])
        if idx == cycle_idx[1]
            break
        else
            push!(cycle_idx,idx)
        end
    end
    a = [c_pos[i][1] for i in cycle_idx]
    b = [c_pos[i][2] for i in cycle_idx]

    #add the first point back to the list to close the loop
    push!(a, c_pos[1][1])
    push!(b, c_pos[1][2])

    plot!(a,b, marker=([:hex :d],6,0.4,stroke(2,:gray)), legend = false,
        reuse = false)
    gui()

    return cycle_idx
end


##############################
# Create and solve TSP optimisation model
# Returns m, x, tlapsed, dead
##############################
function solve_opt(N, c_pos, death, cost, ppl, curr_tlapsed)
    # constants
    M = 10000000 # large constant

    speed = 1/(430/3600) # speed of travel by rescue team (s/km)
    speed2 = 1/(1/3600) # speed of combing a unit sq at a node (s/km^2)

    # model
    m = Model(solver=GurobiSolver())

    @variable(m, tlapsed[k=1:N] >= 0) # tlapsed[i] = total time lapsed when team reaches node i
    @variable(m, dead[k=1:N] >= 0) # dead[i] = total deaths at node i
    @variable(m, x[f=1:N,t=1:N], Bin) # x[i][j] is the arc from node i to node j
    @variable(m, 1 <= seq[k=1:N] <= N)

    @objective(m, Min, sum(dead[i] for i=1:N)) # min number of deaths

    @constraint(m, notself[i=1:N], x[f=i,t=i] == 0) # cannot go from node i to node i
    @constraint(m, oneout[i=1:N], sum(x[f=i,t=1:N]) == 1) # from node i, can only go to 1 other node
    @constraint(m, onein[j=1:N], sum(x[f=1:N,t=j]) == 1) # only 1 other node coming to node j

    @constraint(m, tlapsed[1] == curr_tlapsed) # set start node tlapsed to current time lapsed

    for f=1:N
        @constraint(m, dead[f] >= death[f]*tlapsed[f]) # deaths must be more than death rate * time lapsed
        @constraint(m, dead[f] <= ppl[f]) # deaths must be less than total #ppl at each node
        for t=1:N
            # avoid infeasible constraint where
            # tlapsed(start) <= tlapsed(start + 1) <= ... <= tlapsed(end) <= tlapsed(start)
            if (t > 1)
                # tlapsed at node t - tlapsed at node f = time taken to comb node f
                #               + time taken to travel from f to t IF we choose f--t
                @constraint(m, tlapsed[t] - tlapsed[f] >= (cost[f]*speed2+
                    euclidean(c_pos[t],c_pos[f])*speed)*x[f,t] - M*(1-x[f,t]))
                @constraint(m, tlapsed[t] - tlapsed[f] <= (cost[f]*speed2+
                    euclidean(c_pos[t],c_pos[f])*speed)*x[f,t] + M*(1-x[f,t]))
            end
        end
    end

    # MTZ formulation
    @constraint(m, seq[1] == 1)
    for f=2:N
        @constraint(m, seq[f] >= 2)
        for t=2:N
            @constraint(m, seq[f] - seq[t] + 1 <= N*(1 - x[f,t]))
        end
    end

    # solve
    tic()
    status = solve(m)
    toc()

    return m, x, tlapsed, dead
end

######################################################
# Read and parse results from existing tour
# Return tlapsed, cycle_idx, dead
######################################################
function read_and_parse_tour_data(N)
    f = open(tour_result_filename);
    lines = readlines(f)
    close(f)

    tlapsed = Array{Float64}(N)
    dead = Array{Float64}(N)

    for i = 1:N
        # each line has tlapsed, dead
        tlapsed_str, dead_str = split(lines[i])
        tlapsed[i] = parse(Float64, tlapsed_str)
        dead[i] = parse(Float64, dead_str)
    end

    cycle_idx = Array{Int64}(N)

    for i = 1:N
        cycle_idx[i] = i
    end

    return tlapsed, cycle_idx, dead
end

###########################
# Read and parse input
# return N, name, c_pos, death, cost, ppl
###########################
function read_and_parse_data()
    f = open(filename);
    lines = readlines(f)
    N = length(lines)   #N= number of lines in the file. i.e., number of cities
    if (debug)
        N = debug_N
    end
    close(f)

    c_pos = [Vector{Float64}(2) for _ in 1:N]
    death = Array{Float64}(N)
    cost = Array{Float64}(N)
    name = Array{String}(N)
    ppl = Array{Int64}(N)

    for i = 1:N
        # each line has name, x-coord, y-coord, death, cost, #people
        n_str, x_str, y_str, d_str, c_str, p_str = split(lines[i])
        c_pos[i] = [parse(Float64, x_str), parse(Float64, y_str)]
        death[i] = parse(Float64, d_str) # rate of death (num of people/second)
        cost[i] = parse(Float64, c_str) # cost (in km^2) to comb for people in node i
        ppl[i] = parse(Int64, p_str) # number of ppl at each node
        name[i] = n_str
    end

    a = [c_pos[i][1] for i in 1:N]
    b = [c_pos[i][2] for i in 1:N]

    scatter(a,b, marker=([:hex :d],6,0.4,stroke(2,:gray)), legend = false)
    gui()

    return N, name, c_pos, death, cost, ppl
end

##################
# HELPER FUNCTIONS
#################

# Returns a random number between start_idx and end_idx
function rand_between(start_idx, end_idx)
    return rand(start_idx:end_idx)
end

# Multiplier to get new death for new information
function get_death_multiplier()
    return rand_between(2, 5)
end

# Generate new input for new TSP problem
function generate_new_input(curr_node, change_node_idx, N, name,
        cycle_idx, c_pos, death, cost, ppl)
    new_N = length(cycle_idx) - curr_node + 1
    new_c_pos = [Vector{Float64}(2) for _ in 1:new_N]
    new_death = Array{Float64}(new_N)
    new_cost = Array{Float64}(new_N)
    new_name = Array{String}(new_N)
    new_ppl = Array{Int64}(new_N)
    new_idx = 1
    for j=curr_node:N
        new_c_pos[new_idx][1] = c_pos[cycle_idx[j]][1]
        new_c_pos[new_idx][2] = c_pos[cycle_idx[j]][2]
        new_death[new_idx] = death[cycle_idx[j]]
        # change death rate of chosen node by random percentage
        if j == change_node_idx
            new_death[new_idx] *= get_death_multiplier()
            # write the changed node to file
            open(results_filename, "a") do f
                write(f, string("New info at ", name[cycle_idx[change_node_idx]],
                    ": ", death[cycle_idx[j]], " to ", new_death[new_idx], "\n"))
            end
        end
        new_cost[new_idx] = cost[cycle_idx[j]]
        new_name[new_idx] = name[cycle_idx[j]]
        new_ppl[new_idx] = ppl[cycle_idx[j]]
        new_idx += 1
    end
    return (new_N, new_name, new_c_pos, new_death, new_cost, new_ppl)
end

# Print new TSP (each node's lat lon death) based to file
function print_cycle(cycle_idx, name, c_pos, death, tlapsed, dead)
    open(results_filename, "a") do f
        write(f, "#####################Start New TSP#####################\n")
        for i=1:length(cycle_idx)
            node_info = string(name[cycle_idx[i]], " : ", c_pos[cycle_idx[i]][1],
                " : ", c_pos[cycle_idx[i]][2], " : ", death[cycle_idx[i]], " : ",
                tlapsed[cycle_idx[i]], " : ", dead[cycle_idx[i]], "\n")
            write(f, node_info)
        end
        write(f, "#####################End New TSP#####################\n")
    end
end

# Print node lat lon death to file
function print_node(node_idx, name, c_pos, death, tlapsed, dead)
    open(results_filename, "a") do f
        node_info = string("Reached ", name[node_idx] , " : ",
            c_pos[node_idx][1], " : ", c_pos[node_idx][2],
            " : ", death[node_idx], " : ", tlapsed[node_idx], " : ",
            dead[node_idx], "\n")
        write(f, node_info)
    end
end


## MAIN CODE STARTS HERE ##
plotly()

# we want to read a saved tour instead of generating it from input data file
if tour_exists
    filename = tour_filename
end

# Read data file
(N, name, c_pos, death, cost, ppl) = read_and_parse_data()
println("Read in data file. There are ", N, " nodes.")

# write headers to file
open(results_filename, "w") do f
    if tour_exists
        write(f, string("Starting to traverse tour with ", N, " nodes\n"))
    else
        write(f, string("Starting disaster optimisation for ", N, " nodes\n"))
    end
    write(f, string("New information comes in with probability ",
        new_info_prob, "\n"))
end

# Generate first TSP based on input data
(tlapsed, cycle_idx, dead) = generate_tsp(N, c_pos, death, cost, ppl, 0, true)
print_cycle(cycle_idx, name, c_pos, death, tlapsed, dead)

# Traverse the TSP cycle
curr_node = 1
while curr_node <= length(cycle_idx)
    print_node(cycle_idx[curr_node], name, c_pos, death, tlapsed, dead)
    gen_prob = rand()
    if (gen_prob < new_info_prob && length(cycle_idx) - curr_node > 2)
        # new information comes in!
        # generate the node index which is being affected
        change_node_idx = rand_between(curr_node + 1, length(cycle_idx))
        # organise necessary input for remaining nodes
        (new_N, new_name, new_c_pos, new_death, new_cost, new_ppl) = generate_new_input(
            curr_node, change_node_idx, N, name, cycle_idx, c_pos, death, cost, ppl)
        # generate new tsp
        (tlapsed, cycle_idx, dead) = generate_tsp(new_N, new_c_pos, new_death,
            new_cost, new_ppl, tlapsed[cycle_idx[curr_node]], false)
        print_cycle(cycle_idx, new_name, new_c_pos, new_death, tlapsed, dead)
        # assign new variables to old variables
        c_pos = new_c_pos
        death = new_death
        cost = new_cost
        name = new_name
        ppl = new_ppl
        N = new_N
        # start from the node after start node, which is curr node
        curr_node = 2
    else
        curr_node += 1
    end
end

# Print results_filename
println("Your rescue mission is complete!")
println("Results are written to ", results_filename)
