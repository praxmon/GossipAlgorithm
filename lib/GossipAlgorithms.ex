defmodule GossipAlgorithms do
    
    def gossip(pid) do
        count=NetworkNode.getRumourCount(pid)
        #IO.puts count
        if(count<10) do
            #fetch and send messages to the neighbors resursively.
            neighbour_list=NetworkNode.getNeighbours(pid,"gossip")
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

    def pushsum(pid) do

        #send other half to neighbor if counter <3
        counter = NetworkNode.getCounter(pid)
        if (counter < 3) do
            #before sending just do half...
            {s,w}=NetworkNode.getSWtuple(pid)
            {s,w}={s/2,w/2}
            #set yourself with half
            NetworkNode.updateSelf(pid,{s,w})
            neighbour_list=NetworkNode.getNeighbours(pid,"push-sum")
            random_pid = Enum.random(neighbour_list)
            NetworkNode.sendSWtuple(random_pid,{s,w})
            pushsum(pid)
        end

    end
    
end