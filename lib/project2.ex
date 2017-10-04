defmodule Project2 do
  @moduledoc """
  Documentation for Project2.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Project2.hello
      :world

  """
  def main (args) do
    # IO.puts args
    # IO.puts length args

    if( length(args) < 3) do
      IO.puts "Please specify three arguments"
      exit(:shutdown)
    end
    #IO.puts is_list(args)
    #IO.puts is_tuple(args)
    args_tup=List.to_tuple(args)

    numNodes=elem(args_tup,0)
    topology=elem(args_tup,1)
    algorithm=elem(args_tup,2)
    # Enum.each(args,fn op -> (
    #   IO.puts op
    # ) end)



    IO.puts "numNodes:" <> numNodes
    IO.puts "topology:" <> topology
    IO.puts "algorithm:" <> algorithm

    #start the main stuff here...
    #note: important to convert this to integer...
    numNodes=String.to_integer(numNodes)
    #TODO: make network manager global so that nodes can report back for convergence....

    cond do
      topology == "full" ->
        IO.puts "To implement"
      topology == "2D" ->
        IO.puts "To implement"
      topology == "line" ->
        NetworkManager.initLine(numNodes,algorithm)
      topology == "imp2D" ->
        IO.puts "To implement"
    end

    IO.puts "Should reach here"
    endlesswait()
  end

  def endlesswait do
    endlesswait()
  end
end
