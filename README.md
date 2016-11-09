# Parsing a Panda in 0.4 Seconds With Elixir

I attended the first Edinburgh Elixir meet-up on Monday.
It was a great social event with around ~20 attendees.
Most of which were first time Elixir users.

We started off with a stand up where people introduced themselves and explained why they were interested in Elixir.
After this we split into pairs to take part in a code kata.
The code kata involved [counting the DNA Nucleotides  of a given string](http://rosalind.info/problems/dna/).

After an hour when everyone was done with the kata three of the attendees, myself included, who had prior experience in Elixir presented their group's solutions.
All three solutions were quite similar.
They were based on recursion and used pattern matching, which is very common in Elixir.

It was apparent however that all three were quite inefficient.
The dataset that was being tested was quite small so there was no issue.
But had the dataset been large the programs would take quite a while to complete.
Due to this I decided to investigate how long it would take to parse a large DNA set and what would be the most efficient way to do so.

An attendee at the event had mentioned parsing some Panda DNA.
So naturally I then went to [https://www.ncbi.nlm.nih.gov/](https://www.ncbi.nlm.nih.gov/) and downloaded some Panda DNA.
The largest dataset I could find was around 32,000 lines of text at 2.1MB.
It's worth noting that this is only an extract of Panda DNA as I was not able to find a _complete_ set.

## First Attempt - Recursion and Pattern Matching

```elixir
# takes more than 10 minutes to complete
defmodule PandaDna do
  @nucleotides %{:A => 0, :C => 0, :G => 0, :T => 0}

  def sort_nucleotides(""), do: @nucleotides
  def sort_nucleotides(dna_string) do
    dna_string
    |> String.graphemes
    |> group_nucleotides
  end

  defp group_nucleotides(dna), do: group_nucleotides(dna, 0, @nucleotides)
  defp group_nucleotides(dna, index, acc) when index == length(dna), do: acc
  defp group_nucleotides(dna, index, acc) do
    current_char = dna |> Enum.at(index) |> String.to_atom
    matching_value = acc[current_char]

    if matching_value == nil do
      group_nucleotides(dna, index + 1, acc)
    else
      acc = %{acc | current_char => matching_value + 1}
      group_nucleotides(dna, index + 1, acc)
    end
  end
end
```

The first attempt at parsing the Panda DNA uses the solution that myself and my kata buddy created whilst at the Elixir meet up.
This initial solution involved splitting the data string into a list and recursively iterating that list whilst updating a key value map based on the results.

I had a feeling that this solution would take a long time to parse the 2.1MB of Panda DNA so when setting up my tests I added a timeout of 10 minutes.
This meant that if the program took longer than ten minutes to complete it would be terminated.

> It's worth noting that I preloaded the dataset before running the tests. So the time it takes to read the file is not included in the test execution timestamp.

Needless to say it did take longer than ten minutes.
To double check that it was definitely working I added some tests using smaller datasets.
This confirmed that it did indeed work and that it was just quite slow.

So the result of my first solution took longer than 10 minutes.
I assume it would eventually complete but I wasn't willing to wait around and find out when.

## Second Attempt - Using an Elixir Stream

```elixir
# completes in 2.6 - 2.9 seconds
defmodule PandaDna do
  @nucleotides %{:A => 0, :C => 0, :G => 0, :T => 0}

  def sort_nucleotides(""), do: @nucleotides
  def sort_nucleotides(dataset) do
    dataset
    |> String.graphemes
    |> Stream.scan(@nucleotides, &group_nucleotides/2)
    |> Enum.at(-1)
  end

  defp group_nucleotides(dna, acc) do
    current_char = dna |> String.to_atom
    matching_value = acc[current_char]

    if matching_value == nil do
      acc
    else
      %{acc | current_char => matching_value + 1}
    end
  end
end
```

One of the main issues with the initial solution is that it tries to iterate over the entire dataset.
Creating a Stream of the data is a much better solution.
Using Streams in Elixir is not difficult.
Elixir has a built in Stream module created specifically for this purpose.

The `sort_nucleotides` function was updated to use a Stream instead of recursively iterating the list.
The `Stream.scan/2` function takes an accumulator and a callback function.
It passes the accumulator as the second argument to the callback and updates the accumulator based on what is returned.
Once the stream has reached the end of the dataset, it then returns a list of the returned accumulators.
We only need the final one, piping in `Enum.at(-1)` will return the last item in the list.

Amazingly using this approach the program now runs in less than 3 seconds, with tests completing in between 2.6 and 2.9 seconds.
This is a phenomenal speed increase.
However it is possible for Elixir to split the load over multiple processes.
With this in mind let's take a look at my final and fastest attempt.

## Final Attempt - Using Flow

```elixir
# completes in 0.4 seconds
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
```

I knew that Elixir was particularly good at splitting processes and handling concurrent events, I didn't have much knowledge of this however.
So I went to the [elixir-lang slack channel](https://elixir-lang.slack.com) to seek some advice.
The guys there were incredibly helpful and suggested I use [Flow](https://hexdocs.pm/gen_stage/Experimental.Flow.html).

The description on [elixir-lang.org](http://elixir-lang.org) best sums up what Flow is.

> Flow: allows us to express our computations similarly to streams, except they will run across multiple stages instead of a single process.

After a quick look at the docs and some guidance from the guys on the elixir slack channel I had a DNA parser that used Flow.
It's also worth mentioning that as well as adding Flow some other changes were made to the final solution.
Replacing `String.graphemes` with `:erlang.binary_to_list` doubled the execution speed.
In order to use this I updated the `@nucleotides` map to use char codes instead of atoms.

I was also forced to add a new function `format_groupings` which took the results from Flow and formatted them to give the expected result.

With these changes in place I ran the tests and astoundingly the program completed, with the correct result, in as fast as 0.4 seconds.

## Summary

For me the speed increase from the first to the last solution was unimaginable.
Going from a program that takes over ten minutes to a program that takes 0.4 seconds to parse a 2.1MB is a big achievement.

This also shows that it is important to utilise the functionality that a language offers.
I could have stopped after the first attempt but instead I pursued a better solution.
The journey to the final program has greatly increased my appreciation and knowledge of Elixir.
The syntax and conciseness of the language is just as impressive as it's performance.
The program contains only 36 lines of code and is highly readable.

I look forward to using Elixir again.
I also encourage you to pursue better, more performant code.

All code and tests are contained within this repo.
