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


    def initFull(numnodes, algorithm) do
        {:ok,nwmngr_pid} = start_link(:oned,[])
        node_list=spawn_nodes(numnodes,algorithm)
        node_tuple=List.to_tuple(node_list)
        n = length(node_list)
        Enum.each(node_list, fn(ele) -> (
            NetworkNode.populateNeighbours(ele, node_list)
        )end)
    end

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

    def spawn_nodes_2d(numnodes, algorithm) do
        numCols = :math.ceil(:math.sqrt(numnodes))
        numRows = :math.ceil(:math.sqrt(numnodes))
        range = 1..round(numRows)
        outmap = Enum.reduce(range, %{}, fn(y, accout) -> (
            inmap = Enum.reduce(range, %{}, fn(x, accin) -> (
                if algorithm == "push-sum" do
                    
                end
                if algorithm == "gossip" do
                    {:ok, pid} = NetworkNode.start({:gossip, 0}, [])
                    Map.put(accin, x, pid)
                end
            )end)
            Map.put(accout, y, inmap)
        )end)
        # IO.inspect outmap
        outmap
    end

    def init2D(numnodes, algorithm, imperfect) do
        {:ok,nwmngr_pid} = start_link(:oned,[])
        node_map = spawn_nodes_2d(numnodes, algorithm)
        # IO.inspect node_map
        n = :math.ceil(:math.sqrt(numnodes))
        Enum.each(node_map, fn({r,row_map}) -> (
            Enum.each(row_map, fn({c, cur_pid}) ->(
                neighbor_list = cond do
                    r == 1 ->
                        cond do
                            c==1 ->
                                [node_map[r][c+1]] ++ [node_map[r+1][c]]
                            c==n->
                                [node_map[r+1][c]] ++ [node_map[r][c-1]]
                            1<c && c<n ->
                                [node_map[r][c-1]] ++ [node_map[r][c+1]] ++ [node_map[r+1][c]]
                        end
                    r == n ->
                        cond do
                            c == 1->
                                [node_map[r-1][c]] ++ [node_map[r][c+1]]
                            c == n ->
                                [node_map[r-1][c]] ++ [node_map[r][c-1]]
                            1<c && c<n ->
                                [node_map[r][c-1]] ++ [node_map[r][c+1]] ++ [node_map[r-1][c]]
                        end
                    1<r && r<n ->
                        cond do
                            c==1 ->
                                [node_map[r-1][c]] ++ [node_map[r+1][c]] ++ [node_map[r][c+1]]
                            c==n ->
                                [node_map[r-1][c]] ++ [node_map[r+1][c]] ++ [node_map[r][c-1]]
                            1<c && c<n ->
                                [node_map[r-1][c]] ++ [node_map[r+1][c]] ++ [node_map[r][c-1]] ++ [node_map[r][c+1]]
                        end
                end
                if(imperfect) do
                    range = 1..round(n)
                    r = Enum.random(range)
                    c = Enum.random(range)
                    NetworkNode.populateNeighbours(cur_pid, neighbor_list ++ [node_map[r][c]])
                end
                if (imperfect == false) do
                    NetworkNode.populateNeighbours(cur_pid, neighbor_list)
                end
            )end)
        )end)
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