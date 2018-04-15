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
Generated TSP with objective value 2513.05484912681 [0]
#####################Start New TSP#####################
AngMoKio : 103.8454342 : 1.3691149 : 0.00608812949640288 : -0.0
Bishan : 103.835212 : 1.352585 : 0.00604085926254014 : 50184.16271415728
BukitBatok : 103.763679599999 : 1.3590288 : 0.00597711331260395 : 77616.7640150376
BukitMerah : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 117685.58331882232
Bedok : 103.9273405 : 1.3236038 : 0.00605974732409195 : 169310.51691026124
#####################End New TSP#####################
Reached AngMoKio : 103.8454342 : 1.3691149
Generated TSP with objective value 2186.3341571119345 [0]
#####################Start New TSP#####################
AngMoKio : 103.835212 : 1.352585 : 0.00604085926254014 : -0.0
BukitBatok : 103.9273405 : 1.3236038 : 0.0242389892963678 : 27432.808571286514
Bedok : 103.763679599999 : 1.3590288 : 0.00597711331260395 : 105518.21048622021
Bishan : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 145587.02979000472
#####################End New TSP#####################
Reached Bishan : 103.835212 : 1.352585
Generated TSP with objective value 2589.7645310319444 [0]
#####################Start New TSP#####################
Bishan : 103.9273405 : 1.3236038 : 0.0242389892963678 : -0.0
BukitBatok : 103.763679599999 : 1.3590288 : 0.0239084532504158 : 78085.40191493373
BukitMerah : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 118154.22121871822
#####################End New TSP#####################
Reached Bedok : 103.9273405 : 1.3236038
Reached BukitBatok : 103.763679599999 : 1.3590288
```

## How to read results
* Starting disaster optimisation for `N` nodes
* New information comes in with probability `new_info_prob`
* Generated TSP with objective value `objective_value` [`num_cuts_for_subtour_elimination`]
* Each generated TSP node is printed as: `name : lat : lon : death_rate : tlapsed`
* Each traversed TSP node is printed as: `Reached name : lat : lon`
