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
            Enum.each(neighbour_list, fn(neighbor) ->(
                NetworkNode.sendRumour(neighbor)
            )end)
            gossip(pid)
        else
            IO.puts "Node has completed 10 transmissions..."
        end
    end
    
end