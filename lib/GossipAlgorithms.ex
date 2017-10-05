defmodule GossipAlgorithms do
    
    def gossip(pid) do
        count=NetworkNode.getRumourCount(pid)
        #IO.puts count
        if(count<10) do
            #fetch and send messages to the neighbors resursively.
            neighbour_list=NetworkNode.getNeighbours(pid)
            #IO.inspect neighbour_list
            #IO.puts "Inside gossip"
            #TODO: consider doing a spawn enum maybe? might be a bit too heavy for full network...
            random_pid = Enum.random(neighbour_list)
            NetworkNode.sendRumour(random_pid)
            gossip(pid)
        else
            NetworkNode.informManager()
        end
    end
    
end