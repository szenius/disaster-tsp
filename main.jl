using JuMP, Gurobi, Distances, Plots

debug = true
debug_N = 10

new_info_prob = 1.0

function generate_tsp(N, c_pos, death, cost)
    # Solve initial assignment problem
    (m, x, tlapsed) = solve_assignment(N, c_pos, death, cost)
    println("Solved initial assignment problem")
    for i=1:N
        println(i, " : ", getvalue(tlapsed[i])*death[i], " [", getvalue(tlapsed[i]), "]")
    end

    # Subtour elimination
    tic()
    count = 0
    (isDone, m) = subtour_elimination(m, x, N)
    while !isDone
        status = solve(m)
        count += 1
        println("cut number: ", count)
        (isDone, m) = subtour_elimination(m, x, N)
    end
    toc()
    println("Objective value:", getobjectivevalue(m))
    return plot_tour(x, c_pos, N)
end

##############################
# eliminate subtours
##############################
function subtour_elimination(m, x, N)
    x_val = getvalue(x)    #initial solution

    # find cycle
    cycle_idx = Array{Int}(0)
    push!(cycle_idx, 1)                  # tour starts at the first city
    while true
        v, idx = findmax(x_val[f=cycle_idx[end],t=1:N])
        if idx == cycle_idx[1]
            break
        else
            push!(cycle_idx,idx)
        end
    end

    if length(cycle_idx) < N
        @constraint(m, sum(x[f=cycle_idx,t=cycle_idx]) <= length(cycle_idx)-1)
        return false, m
    end
    return true, m
end

##############################
# plot tour
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

    plot!(a,b, marker=([:hex :d],6,0.4,stroke(2,:gray)), legend = false, reuse = false)
    gui()

    return cycle_idx
end


##############################
# Find solution for assignment problem
##############################
function solve_assignment(N, c_pos, death, cost)
    # constants
    M = 10000000 # large constant

    speed = 1/(430/3600) # speed of travel by rescue team (s/km)
    speed2 = 1/(1/3600) # speed of combing a unit square while rescuing at a node (s/km^2)

    # model
    m = Model(solver=GurobiSolver())

    @variable(m, tlapsed[k=1:N] >= 0) # tlapsed[i] is the total time lapsed when team reaches node i
    @variable(m, x[f=1:N,t=1:N], Bin) # x[i][j] is the arc from node i to node j

    @objective(m, Min, sum(death[i]*tlapsed[i] for i=1:N))

    @constraint(m, notself[i=1:N], x[f=i,t=i] == 0) # cannot go from node i to node i
    @constraint(m, oneout[i=1:N], sum(x[f=i,t=1:N]) == 1) # from node i, can only go to 1 other node
    @constraint(m, onein[j=1:N], sum(x[f=1:N,t=j]) == 1) # only 1 other node coming to node j
    @constraint(m, tlapsed[1] == 0) # time lapsed at node 1 (start) is 0

    for f=1:N
        for t=2:N
            @constraint(m, x[f,t]+x[t,f] <= 1) # disallow i --> j --> i loops

            # tlapsed at node t - tlapsed at node f = time taken to comb node f + time taken to travel from f to t IF we choose f--t
            @constraint(m, tlapsed[t] - tlapsed[f] >= (cost[f]*speed2+euclidean(c_pos[t],c_pos[f])*speed)*x[f,t] - M*(1-x[f,t]))
            @constraint(m, tlapsed[t] - tlapsed[f] <= (cost[f]*speed2+euclidean(c_pos[t],c_pos[f])*speed)*x[f,t] + M*(1-x[f,t]))
        end
    end

    # solve
    tic()
    status = solve(m)
    toc()

    return m, x, tlapsed
end

###########################
# Read and parse input
###########################
function read_and_parse_data(filename)
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

    for i = 1:N
        n_str, x_str, y_str, d_str, c_str, p_str = split(lines[i])  # each line has no, x-coord, y-coord n the data file
        c_pos[i] = [parse(Float64, x_str), parse(Float64, y_str)]
        death[i] = parse(Float64, d_str) # rate of death (num of people/second)
        cost[i] = parse(Float64, c_str) # cost (in km^2) to comb for people in node i
    end

    a = [c_pos[i][1] for i in 1:N]
    b = [c_pos[i][2] for i in 1:N]

    scatter(a,b, marker=([:hex :d],6,0.4,stroke(2,:gray)), legend = false)
    gui()

    return N, c_pos, death, cost
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
function generate_new_input(curr_node, change_node_idx, N, cycle_idx, c_pos, death, cost)
    new_N = length(cycle_idx) - curr_node
    new_c_pos = [Vector{Float64}(2) for _ in 1:new_N]
    new_death = Array{Float64}(new_N)
    new_cost = Array{Float64}(new_N)
    new_idx = 1
    for j=curr_node+1:N
        new_c_pos[new_idx][1] = c_pos[cycle_idx[j]][1]
        new_c_pos[new_idx][2] = c_pos[cycle_idx[j]][2]
        new_death[new_idx] = death[cycle_idx[j]]
        # change death rate of chosen node by random percentage
        if j == change_node_idx
            new_death[new_idx] *= get_death_multiplier()
        end
        new_cost[new_idx] = cost[cycle_idx[j]]
        new_idx += 1
    end
    return (new_N, new_c_pos, new_death, new_cost)
end

# Print cycle lat long death based on cycle_idx
function print_cycle(cycle_idx, c_pos, death)
    for i=1:length(cycle_idx)
        println(cycle_idx[i], " : ", c_pos[i][1], " ", c_pos[i][2], " : ", death[i])
    end
end

plotly()

# Read data file
(N, c_pos, death, cost) = read_and_parse_data("C:/Users/SZEYING/LocationFinal2.txt")
println("Read in data file. There are ", N, " nodes.")

# Generate first TSP based on input data
cycle_idx = generate_tsp(N, c_pos, death, cost)
print_cycle(cycle_idx, c_pos, death)

# Traverse the TSP cycle
curr_node = 1
while curr_node != length(cycle_idx)
    println("Reached ", c_pos[cycle_idx[curr_node]][1], " : ", c_pos[cycle_idx[curr_node]][2])
    gen_prob = rand()
    if (gen_prob < new_info_prob && length(cycle_idx) - curr_node > 2)
        # new information comes in!
        println("New information [", gen_prob, "]")
        # generate the node index which is being affected
        change_node_idx = rand_between(curr_node + 1, length(cycle_idx))
        # organise necessary input for remaining nodes
        (new_N, new_c_pos, new_death, new_cost) = generate_new_input(curr_node, change_node_idx, N, cycle_idx, c_pos, death, cost)
        # generate new tsp
        cycle_idx = generate_tsp(new_N, new_c_pos, new_death, new_cost)
        print_cycle(cycle_idx, new_c_pos, new_death)
        # assign new variables to old variables
        c_pos = new_c_pos
        death = new_death
        cost = new_cost
        N = new_N
        # start from beginning of cycle
        curr_node = 1
    else
        curr_node += 1
    end
end
