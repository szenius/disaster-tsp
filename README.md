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
Generated TSP with objective value 3422.52124162072 [0]
#####################Start New TSP#####################
AngMoKio : 103.8454342 : 1.3691149 : 0.00608812949640288 : -0.0 : 0.0
Bishan : 103.835212 : 1.352585 : 0.02416343705016056 : 50184.16271415728 : 1212.6218566585542
BukitBatok : 103.763679599999 : 1.3590288 : 0.00597711331260395 : 77616.7640150376 : 463.9241934755204
BukitMerah : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 117685.58331882211 : 719.9962396990694
Bedok : 103.9273405 : 1.3236038 : 0.00605974732409195 : 169310.51691026057 : 1025.9789517875763
#####################End New TSP#####################
Reached Bishan : 103.835212 : 1.352585 : 0.02416343705016056 : 50184.16271415728 : 1212.6218566585542
Generated TSP with objective value 5222.350757647939 [0]
#####################Start New TSP#####################
Bishan : 103.835212 : 1.352585 : 0.02416343705016056 : 50184.16271415728 : 1212.6218566585542
Bedok : 103.9273405 : 1.3236038 : 0.0242389892963678 : 77616.97128544383 : 1881.3569362043597
BukitBatok : 103.763679599999 : 1.3590288 : 0.00597711331260395 : 155702.37320037745 : 930.6507276600045
BukitMerah : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 195771.19250416197 : 1197.7212371250203
#####################End New TSP#####################
Reached Bedok : 103.9273405 : 1.3236038 : 0.0242389892963678 : 77616.97128544383 : 1881.3569362043597
Generated TSP with objective value 6801.681083969403 [0]
#####################Start New TSP#####################
Bedok : 103.9273405 : 1.3236038 : 0.0242389892963678 : 77616.97128544383 : 1881.3569362043597
BukitBatok : 103.763679599999 : 1.3590288 : 0.0239084532504158 : 155702.37320037762 : 3722.6029106400224
BukitMerah : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 195771.19250416197 : 1197.7212371250203
#####################End New TSP#####################
Reached BukitBatok : 103.763679599999 : 1.3590288 : 0.0239084532504158 : 155702.37320037762 : 3722.6029106400224
Reached BukitMerah : 103.823918199999 : 1.2819046 : 0.00611796465968586 : 195771.19250416197 : 1197.7212371250203
```

## How to read results
* Starting disaster optimisation for `N` nodes
* New information comes in with probability `new_info_prob`
* Generated TSP with objective value `objective_value` [`num_cuts_for_subtour_elimination`]
* For each node in TSP cycle: `name : lat : lon : deathrate : tlapsed :  numdead`
* For each node we traverse: `Reached name : lat : lon : deathrate : tlapsed : numdead`
