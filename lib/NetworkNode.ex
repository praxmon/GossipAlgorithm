defmodule NetworkNode do
    use GenServer

    #note: this is a single tuple as network manager will pass it only list of neighbours and not the topology.
    #TODO: figure out something for full neighbours
    
    #Init for gossip {neighbours,count}
    def init ({:gossip,count}) do
        state_list_neighbours=[]
        state_count=count
        #return the state tuple.
        {:ok, {state_list_neighbours,state_count}}
    end


    def init ({:pushsum,s}) do
        state_list_neighbours=[]
        state_sw={s,1}
        #return the state tuple
        {:ok,{state_list_neighbours,state_sw}}
    end
    
    #based on the algorithm selected, appropriate init will be selected. 
    # leave opts as [] 
    def start(init_option, opts) do
        GenServer.start(__MODULE__, init_option ,opts)
    end

    def populateNeighbours(pid, list_neighbours) do
        #note:
        # IO.inspect {pid, list_neighbours}
        GenServer.cast(pid,{:add,list_neighbours})
    end

    #function to send gossip to the pid specified.
    def sendRumour(pid) do
        GenServer.cast(pid,{:rumor,pid})
    end

    #function to fetch the count for the specified pid
    def getRumourCount(pid) do
        GenServer.call(pid,:rumourcount)
    end

    #function to fetch the neighbors
    def getNeighbours(pid) do
        GenServer.call(pid,:neighbourlist)
    end


    #function to send {s,w} for pushsum

    # def sendPushSum() do
        
    # end

    # Callbacks

    #cast call back for populating the neigbhbour state_tuple
    def handle_cast({:add,list_neighbours},{state_list_neighbours,state_count}) do
        #:timer.sleep 2000
        #IO.puts "value has been added :"
        #re binding
        #IO.inspect list_neighbours
        state_list_neighbours=list_neighbours ++ state_list_neighbours
        {:noreply,{state_list_neighbours,state_count}}
    end

    #cast call back to handle algorithm start when rumor recieved.
    def handle_cast({:rumor,pid},{state_list_neighbours,state_count}) do
    
        if state_count < 1 do
            spawn(GossipAlgorithms, :gossip, [pid])
        end
        state_count=state_count+1

        {:noreply,{state_list_neighbours,state_count}}
    end

    #call back to fetch the neighbours
    def handle_call(:neighbourlist,_from,{state_list_neighbours,state_count}) do
        #IO.puts "Fetch the neighbours:"
        {:reply,state_list_neighbours,{state_list_neighbours,state_count}}
    end

    #call back to fetch the count
    def handle_call(:rumourcount,_from,{state_list_neighbours,state_count}) do
        {:reply,state_count,{state_list_neighbours,state_count}}
    end

    def informManager() do
        GenServer.cast({:global, :daddy}, {:count})
    end

end