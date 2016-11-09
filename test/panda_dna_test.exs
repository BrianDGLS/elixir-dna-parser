defmodule PandaDnaTest do
  use ExUnit.Case
  doctest PandaDna

  @nucleotides %{?A => 0, ?C => 0, ?G => 0, ?T => 0}

  # @tag :skip
  test "An empty string returns the nucleotides map with initial values" do
    assert PandaDna.sort_nucleotides("") == @nucleotides
  end

  # @tag :skip
  test "Works with invalid nucleotides" do
    assert PandaDna.sort_nucleotides("ABCDEFGHIJKLMNOP") == %{?A => 1, ?C => 1, ?G => 1, ?T => 0}
  end

  # @tag :skip
  test "Gives correct result for valid strings" do
    test = "GGTCTCTTATGAAGTCTCTATTGGTCTTATTCTTATTGTGCGCCTTGTGAGCGCGTTTGGATCCGCGAAG"
    assert PandaDna.sort_nucleotides(test) == %{?A => 10, ?C => 14, ?G => 19, ?T => 27}
  end

  # @tag :skip
  # @tag timeout: 5000
  test "Test using small data set of Panda DNA" do
    dataset = Application.get_env(:panda, :panda_dataset_small)
    assert PandaDna.sort_nucleotides(dataset) == %{?A => 5676, ?C => 5760, ?G => 6495, ?T => 5040}
  end

  # @tag :skip
  # @tag timeout: 5000
  test "Test using huge data set of Panda DNA" do
    dataset = Application.get_env(:panda, :panda_dataset_large)
    assert PandaDna.sort_nucleotides(dataset) == %{?A => 520700, ?C => 527924, ?G => 595740, ?T => 460880}
  end
end
