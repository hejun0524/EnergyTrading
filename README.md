## Energy Trading

### Objective function
For each individual agent, the objective function is to maximize $\sum_{t=1}^T r_t$,
where $T = 288$ is the total number of time slots of the episodes since we are setting the market to run for 3 days and each time step is 15 minutes.

### Step reward
Let each bid/ask has a fixed duration $t_d$, say 1 hour, which is 4 time slots in our setup. If an order expires, the market will delete that order and let the grid buy/sell energy to the agent. Also at the end of the 3 days simulation, all the unmatched orders will be deleted.

Agents randomly arrive continuously according to an exponential arrival rate. An agent can arrive only if he/she (i) does not have an unexpired order in market at that market time interval, and (ii) has a nonzero quantity on the order to submit. Every time an order is submitted, the market receives and updates the SD ratio, and then assigns the price to the order. For any two agents arrive in the same 15min interval but different real time, the one who arrives second sees a more updated ratio information. However, the market matches orders only at the end of each 15-minute interval.

Then at each time $t$, an in-market agent's reward $r_t$ is as follows:
1. $r_t \in [0, 1]$ based on Zibo's paper. 0 means the auction price is worse than the grid price, 1 means the auction price outperforms the grid price (e.g. seller sells less than 2 dollars gives 0, and sells more than 15 dollars gives 1.)
2. After the agent places an order, he/she can still interact with the grid. Then the reward $r_t$ will also use the total payoff from both auction and grid, at each market time interval. This is the same as in Zibo's paper, which is equation (3) $\Lambda_i = \Lambda_i^{au} + \Lambda_i^{ut}$. This also takes care of order expiration, which counts those as $\Lambda_i^{ut}$. If at that time interval, an agent receives no matches but only expiration, then reward is 0 which is already reflected in the paper.
3. But we still need to subtract the congestion and voltage charges. We have $\Lambda_i = \Lambda_i^{au} + \Lambda_i^{ut} - \text{Charges}$. The charges only show up when a deal is matched by the market.
4. If a match causes any system violation, it will be simply ignored in reward calculation. This match will be disgarded and wait till next round of matching (if not expired.)

### Deep RL
Let $\pi$ be the policy network, which is a neural network for an agent to find out the best parameters. The states are listed below:
1. Time of the day, which is indexed from 1 to 96 ($24 \times 60 \div 15$).
2. Panel configuration.
3. Battery configuration.
4. Battery storage status.
5. Demand forecast of the next hour (4 slots).
6. Market data (current supply-demand information).
7. Market history (previous day's SD ratio information of the corresponding 4 slots).

Although an order consists of price, quantity and duration, here we let the agent only determines the quantity to submit.
1. $Q = \pi(\text{states})$, which is the only action for RL.
2. $P = 15 - 13 \times SDR$, (grid prices \$2 and \$15 as the floor and ceiling.) Here, $SDR \in [0, 1]$. If $SDR$ falls out of this range, we clip it to either the floor or the ceiling.
3. $t_d = 4$, which is one hour fixed.

### Constraints
The constraints are only about the $Q$. At each time, the agent has a different range for $Q$. Let $Q$ at each time $t$ be $Q_t$, determined through the policy NN.
1. The maximal amount he/she can buy is $Q^B_t = \sum_{\tau=t}^{\max(t+t_d, T)} L_d + (\overline{B} - B_t)$ which is the sum of the hour's load demand and how much more the battery can charge (pure consumer has the second term equal to 0).
2. The maximal amount he/she can sell is $Q^S_t = B_{\tau}$, which is the current level. 
3. The range is therefore $Q_t \in [-Q^B_t, Q^S_t]$.

There are 3 ways to model it. It seems to me the second one makes more sense.
1. First is to let the NN output layer to be either a sigmoid function or $\tanh$, and then map the value to this range. This ensures that the agent's action always satisfy the changing range. 
2. The second way is to let the NN output the quantity directly and clip it by the range. This way the agent only learns about actions within the action space and the weights of the network would eventually be adjusted to only output actions within this action space, provided that the boundaries aren't the optimal actions.
3. The third one is to use punishment term in the reward function. But I do not know how much punishment to set. 