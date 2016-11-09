defmodule PandaDna do
  alias Experimental.Flow

  @nucleotides %{?A => 0, ?C => 0, ?G => 0, ?T => 0}

  def sort_nucleotides(""), do: @nucleotides
  def sort_nucleotides(dataset) do
    dataset
    |> :erlang.binary_to_list
    |> Flow.from_enumerable
    |> Flow.reduce(fn -> @nucleotides end, &group_nucleotides/2)
    |> Enum.to_list
    |> Stream.scan(@nucleotides, &format_groupings/2)
    |> Enum.at(-1)
  end

  defp format_groupings(dna, acc) do
    dna = dna
    |> Tuple.to_list

    key = dna |> Enum.at(0)
    value = dna |> Enum.at(1)

    %{acc | key => acc[key] + value}
  end

  defp group_nucleotides(dna, acc) do
    matching_value = acc[dna]

    if matching_value == nil do
      acc
    else
      %{acc | dna => matching_value + 1}
    end
  end
end
