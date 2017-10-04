defmodule NetworkManager do
    use GenServer


    #based on the algorithm the initialization for spawning the network nodes changes
    def spawn_nodes(numnodes,algorithm) do

        node_list=cond do
            algorithm == "gossip" ->
                node_list= Enum.map(1..numnodes, fn(_) ->(
                    {:ok,pid}=NetworkNode.start({:gossip,0},[])
                    pid
                )end)
                node_list

            algorithm == "push-sum" ->
                node_list= Enum.map(1..numnodes, fn(x) ->(
                    {:ok,pid}=NetworkNode.start({:pushsum,x},[])
                    pid
                )end)
                node_list
        end
        #return the node list created..
        node_list
    end


    # def initFull(numnodes, algorithm) do
    #     #init list of complete network


    #     # spawn all the children with own subset from the above list...
    #     #
    # end

    # def init2D(numnodes, algorithm) do 

    # end

    def initLine(numnodes,algorithm) do
        {:ok,nwmngr_pid} = start_link(:oned,[])
        node_list=spawn_nodes(numnodes,algorithm)
        node_tuple=List.to_tuple(node_list)
        n = length(node_list)

        #populated the neighbour list

        node_list
        |>Enum.with_index
        |>Enum.each(fn({cur_pid,i}) ->(
            neighbour_list=cond do
                    i > 0 && i < n-1 ->
                        [elem(node_tuple,i-1),elem(node_tuple,i+1)]
                    i == 0           ->
                        [elem(node_tuple,i+1)] 
                    i == n-1         ->
                        [elem(node_tuple,i-1)]
                end

            #IO.inspect neighbour_list
            NetworkNode.populateNeighbours(cur_pid,neighbour_list)
            # IO.inspect NetworkNode.getNeighbours(cur_pid)

        ) end)

        #populateNetworkList(nwmngr_pid,node_list)

        #fetch a random process from the list to start
        start_pid=Enum.random(node_list)

        cond do
            algorithm == "gossip" ->
                NetworkNode.sendRumour(start_pid)
                # IO.puts "Still working on this"
            algorithm == "push-sum" ->
                IO.puts "Not implemented yet"
        end
    
    end


    def start_link(init_ops,opts) do
        #parse arguments if necessary
        GenServer.start_link(__MODULE__,init_ops, opts)
    end


    #for a 1D format
    def init(:oned) do
        state_tuple = {}
        {:ok,state_tuple}
    end

    # #TODO: figure this out for a 2D format...
    # def init({:twod,size}) do
    #     state_tuple_network={}
    # end

    def populateNetworkList(pid,node_list) do
        GenServer.cast(pid,{:add,node_list})
    end

    # def handle_call() do
    #     #handle call if necessary
    # end

    def handle_cast({:add,node_list},state_tuple) do
        state_tuple.append(List.to_tuple(node_list))
        {:noreply, state_tuple}
        #handle cast if necessary
    end
end