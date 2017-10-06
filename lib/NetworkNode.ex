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
        counter=0
        flag=true
        #return the state tuple
        {:ok,{state_list_neighbours,state_sw,counter,flag}}
    end
    
    #based on the algorithm selected, appropriate init will be selected. 
    # leave opts as [] 
    def start(init_option, opts) do
        GenServer.start(__MODULE__, init_option ,opts)
    end

    def populateNeighbours(pid, list_neighbours,algorithm) do
        #note:
        # IO.inspect {pid, list_neighbours}

        if(algorithm == "gossip") do 
            GenServer.cast(pid,{:add,list_neighbours})
        else 
            GenServer.cast(pid,{:addpushsum,list_neighbours})
        end

        
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
    def getNeighbours(pid, algorithm) do
        if(algorithm=="gossip") do
            GenServer.call(pid,:neighbourlistgp)
        else
            GenServer.call(pid,:neighbourlistps)
        end
        
    end

    def informManager() do
        GenServer.cast({:global, :daddy}, {:count})
    end

    #for the first starting point we set the flag to false and start sending.
    #rest of them will be taken care of in the recieve logic
    def startpushsum(pid) do
        #set the flag to false and spawn the process
        setSendOnceFlagToFalse(pid)
        spawn(GossipAlgorithms, :pushsum, [pid])
    end

    def getSWtuple(pid) do
        GenServer.call(pid,:swtuple)
    end

    def sendSWtuple(pid,{s,w}) do
        GenServer.cast(pid,{:sendsw,{s,w},pid})
    end

    def updateSelf(pid,{s,w}) do
        GenServer.cast(pid,{:updatesw,{s,w}})
    end

    def getCounter(pid) do
        GenServer.call(pid,{:getcounter})
    end

    def setCounter(pid,counter) do
        GenServer.cast(pid,{:setcounter,counter})
    end

    def getSendOnceFlag(pid) do
        GenServer.call(pid,{:getonceflag})
    end

    def setSendOnceFlagToFalse(pid) do
        GenServer.cast(pid,{:setonceflagfalse})
    end

    #cast call back for populating the neigbhbour state_tuple
    def handle_cast({:add,list_neighbours},{state_list_neighbours,state_count}) do
        #:timer.sleep 2000
        #IO.puts "value has been added :"
        #re binding
        #IO.inspect list_neighbours
        state_list_neighbours=list_neighbours ++ state_list_neighbours
        {:noreply,{state_list_neighbours,state_count}}
    end

    #cast call back for populating the neigbhbour state_tuple
    def handle_cast({:addpushsum,list_neighbours},{state_list_neighbours,state_sw,counter,flag}) do
        #:timer.sleep 2000
        #IO.puts "value has been added :"
        #re binding
        #IO.inspect list_neighbours
        state_list_neighbours=list_neighbours ++ state_list_neighbours
        {:noreply,{state_list_neighbours,state_sw,counter,flag}}
    end

    #cast call back to handle algorithm start when rumor recieved.
    def handle_cast({:rumor,pid},{state_list_neighbours,state_count}) do
    
        if state_count < 1 do
            spawn(GossipAlgorithms, :gossip, [pid])
        end
        state_count=state_count+1

        {:noreply,{state_list_neighbours,state_count}}
    end

    #call back to set the flag to flase
    def handle_cast({:setonceflagfalse} , {state_list_neighbours,state_sw,state_counter,flag}) do
        flag=false
        {:noreply, {state_list_neighbours,state_sw,state_counter,flag}}
    end

    #call back when we recieve an {s,w} from some process.
    #So the consecutive is also checked through the recieve
    def handle_cast({:sendsw,{s,w},pid}, {state_list_neighbours,state_sw,counter,flag}) do
        {own_s, own_w}=state_sw

        #verify this condition once...
        # if(flag == true) do
        #     flag= false
        #     spawn(GossipAlgorithms, :pushsum, [pid])
        # end

        flag = cond do
                flag == true ->
                    flag = false
                    spawn(GossipAlgorithms, :pushsum, [pid])
                    flag
                true ->
                    flag
            end 

        #difference consecutive

        {new_s,new_w}={own_s+s,own_w+w}

        diff= abs((new_s/new_w) - (own_s/own_w))
        
        counter = cond do 
            diff < :math.pow(10,-10) ->
                counter = cond do
                                counter < 3 ->
                                        counter =counter+1
                                        if(counter ==3) do
                                            NetworkNode.informManager()
                                        end
                                        counter

                                counter >= 3 -> 
                                        counter
                                true ->
                                        counter
                            end
                counter

            true -> 
                counter = cond do
                    counter < 3 -> 
                        counter =0
                        counter
                    true ->
                        counter 
                end
                counter
        end

        # if(diff < :math.pow(10,-10)) do
        #     if(counter < 3) do
        #             counter=counter+1
        #     end
        # else
        #     if(counter < 3) do
        #         counter = 0
        #     end 
        # end 

        state_sw={new_s,new_w}
        {:noreply,{state_list_neighbours,state_sw,counter,flag}}
    end

    #call back to set the consecutive counter for pushsum 
    def handle_cast({:setcounter,counter} , {state_list_neighbours,state_sw,state_counter,flag}) do
        state_counter=counter
        {:noreply,{state_list_neighbours,state_sw,state_counter,flag}}
    end

    #call back to update the {s,w} tuple
    def handle_cast({:updatesw,{s,w}} , {state_list_neighbours,state_sw,state_counter,flag}) do
        state_sw={s,w}
        {:noreply,{state_list_neighbours,state_sw,state_counter,flag}}
    end

    #call back to fetch the neighbours for gossip
    def handle_call(:neighbourlistgp, _from, {state_list_neighbours,state_count}) do
        #IO.puts "Fetch the neighbours:"
        {:reply,state_list_neighbours,{state_list_neighbours,state_count}}
    end

    #call back to fetch the neighbours for push sum
    def handle_call(:neighbourlistps,_from, {state_list_neighbours,state_sw,state_counter,flag}) do
        #IO.puts "Fetch the neighbours:"
        {:reply,state_list_neighbours, {state_list_neighbours,state_sw,state_counter,flag}}
    end

    #call back to fetch the count
    def handle_call(:rumourcount,_from,{state_list_neighbours,state_count}) do
        {:reply,state_count, {state_list_neighbours,state_count}}
    end

    #call back to fetch the {s,w} pair for pushsum
    def handle_call(:swtuple,_from,  {state_list_neighbours,state_sw,state_counter,flag}) do
        {:reply,state_sw, {state_list_neighbours,state_sw,state_counter,flag}}
    end

    #to fetch the consecutive counter for pushsum
    def handle_call({:getcounter}, _from, {state_list_neighbours,state_sw,state_counter,flag}) do
        {:reply,state_counter,{state_list_neighbours,state_sw,state_counter,flag}}
    end

    #call back to get flag for pushsum sending
    def handle_call({:getonceflag} , _from, {state_list_neighbours,state_sw,state_counter,flag}) do
        {:reply, flag, {state_list_neighbours,state_sw,state_counter,flag}}
    end


  

end