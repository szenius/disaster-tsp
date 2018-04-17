using JuMP, Gurobi, Distances, Plots
plotly()

##############################
# Read from data file
##############################
f = open("C:/Users/SZEYING/LocationFinal2.txt");
lines = readlines(f)
N = length(lines)   #N= number of lines in the file. i.e., number of cities
println("Read in data file. There are ", N, " nodes.")
close(f)

# parse input from file into
#     coordinates,
#     death rate (num people per second), and
#     cost (seconds) of combing each node
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


##############################
# Find solution for assignment problem
##############################
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

# print time lapsed
for i=1:N
    println("tlapsed[", i, "]: ", getvalue(tlapsed[i]))
end

##############################
# plot tour generated by above
##############################

x_final = convert(Array{Int64}, getvalue(x))
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

plot!(a,b, marker=([:hex :d],6,0.4,stroke(2,:gray)), legend = false)
gui()

##############################
# formulate TSP with additional constraints to eliminate subtours
##############################

function subtour_elimination(m)
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

    println("cycle_idx: ", cycle_idx)
    println("Length: ", length(cycle_idx))
    if length(cycle_idx) < N
        @constraint(m, sum(x[f=cycle_idx,t=cycle_idx]) <= length(cycle_idx)-1)
        return false
    end
    return true
end

tic()
count = 0
while !subtour_elimination(m)
    status = solve(m)
    count += 1
    println("cut number: ", count)
end
toc()
println("Objective value:", getobjectivevalue(m))

##############################
# plot final TSP tour
##############################
x_final = convert(Array{Int64}, getvalue(x))
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

plot(a,b, marker=([:hex :d],6,0.4,stroke(2,:gray)), legend = false)
gui()