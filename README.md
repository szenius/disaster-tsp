Run `main_death_var.jl`.

# How it works
1. Generate TSP based on input data file
2. According to the generated TSP, the algo starts to traverse the graph, one node at a time.
3. At each node, new information comes in with a preset probability.
4. If new information come in, a new TSP is generated.
5. Repeat steps 2-4 until all nodes are traversed.

# New Information probability
This is the probability of new information coming in at each node. To change, simply modify the variable `new_info_prob`. The range of values for this variable is **[0, 1]**. A value of `1` means that new information comes in at every node traversed, unless there are less than 3 nodes left. A value of `0` means there is no new information coming in.

# Debug mode
In `debug` mode, the algorithm will only run the TSP for `debug_N` nodes instead of the full 42 nodes in our data input file.

To run in debug mode, make sure that the variable `debug` is set to `true`. You can also set `debug_N` according to how many nodes you want to generate a TSP for. On my machine, `debug_N = 5` runs in a minute, and `debug_N = 10` runs in less than 5 minutes.

# Results file
All information regarding the nodes traversed and the TSPs generated is printed to an output file, which filename is of the format `./resultsyymmddHHMM.txt`.

An example of the contents in a result file:
```
Starting disaster optimisation for 5 nodes
New information comes in with probability 1.0
Generated TSP with objective value 2513.054849126803 [0]
#####################Start New TSP#####################
AngMoKio : 103.8454342 : 1.3691149 : 0.00608812949640288 : -0.0 : 0.0
Bishan : 103.835212 : 1.352585 : 0.00604085926254014 : 50184.16271415728 : 303.15546416463854
BukitBatok : 103.763679599999 : 1.3590288 : 0.00597711331260395 : 77616.76401503813 : 463.9241934755236
BukitMerah : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 117685.58331882185 : 719.9962396990678
Bedok : 103.9273405 : 1.3236038 : 0.00605974732409195 : 169310.51691026002 : 1025.9789517875731
#####################End New TSP#####################
Reached AngMoKio : 103.8454342 : 1.3691149 : 0.00608812949640288 : -0.0 : 0.0
New info at BukitMerah: 0.00611796465968586 to 0.02447185863874344
Generated TSP with objective value 3641.607942643832 [0]
#####################Start New TSP#####################
AngMoKio : 103.8454342 : 1.3691149 : 0.00608812949640288 : 0.0 : 0.0
BukitMerah : 103.823918199999 : 1.2819046 : 0.02447185863874344 : 50184.75202530809 : 1228.114157383733
Bishan : 103.835212 : 1.352585 : 0.00604085926254014 : 101809.35127472319 : 615.0159626611144
BukitBatok : 103.763679599999 : 1.3590288 : 0.00597711331260395 : 129241.9525756035 : 772.493795286568
Bedok : 103.9273405 : 1.3236038 : 0.00605974732409195 : 169311.3544905372 : 1025.9840273124164
#####################End New TSP#####################
Reached BukitMerah : 103.823918199999 : 1.2819046 : 0.02447185863874344 : 50184.75202530809 : 1228.114157383733
New info at BukitBatok: 0.00597711331260395 to 0.01793133993781185
Generated TSP with objective value 4936.744028366351 [0]
#####################Start New TSP#####################
BukitMerah : 103.823918199999 : 1.2819046 : 0.02447185863874344 : 50184.75202530809 : 1228.114157383733
BukitBatok : 103.763679599999 : 1.3590288 : 0.01793133993781185 : 101809.5713290926 : 1825.5820324248625
Bishan : 103.835212 : 1.352585 : 0.00604085926254014 : 141878.17262997292 : 857.0660732840408
Bedok : 103.9273405 : 1.3236038 : 0.00605974732409195 : 169310.98120125942 : 1025.9817652737142
#####################End New TSP#####################
Reached BukitBatok : 103.763679599999 : 1.3590288 : 0.01793133993781185 : 101809.5713290926 : 1825.5820324248625
New info at Bishan: 0.00604085926254014 to 0.02416343705016056
Generated TSP with objective value 6279.828090834742 [0]
#####################Start New TSP#####################
BukitBatok : 103.763679599999 : 1.3590288 : 0.01793133993781185 : 101809.5713290926 : 1825.5820324248625
Bishan : 103.835212 : 1.352585 : 0.02416343705016056 : 141878.17262997298 : 3428.2642931361647
Bedok : 103.9273405 : 1.3236038 : 0.00605974732409195 : 169310.98120125942 : 1025.9817652737142
#####################End New TSP#####################
Reached Bishan : 103.835212 : 1.352585 : 0.02416343705016056 : 141878.17262997298 : 3428.2642931361647
Reached Bedok : 103.9273405 : 1.3236038 : 0.00605974732409195 : 169310.98120125942 : 1025.9817652737142
```

## How to read results
* Starting disaster optimisation for `N` nodes
* New information comes in with probability `new_info_prob`
* Generated TSP with objective value `objective_value` [`num_cuts_for_subtour_elimination`]
* New info at `selected_node_to_change` : `old_death_rate` to `new_death_rate`
* For each node in TSP cycle: `name : lat : lon : deathrate : tlapsed :  numdead`
* For each node we traverse: `Reached name : lat : lon : deathrate : tlapsed : numdead`
