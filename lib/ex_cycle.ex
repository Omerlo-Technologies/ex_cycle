defmodule ExCycle do
  @moduledoc """
  Documentation for `ExCycle`.
  """

  alias ExCycle.Rule

  @type t :: %ExCycle{rules: list(Rule.t())}
  @type datetime :: DateTime.t() | NaiveDateTime.t() | Date.t()

  defstruct rules: []

  @doc """
  Defines a new ExCycle struct.

  ## Examples

      iex> new()
      %ExCycle{}

  """
  @spec new() :: t()
  def new, do: %ExCycle{}

  @doc """
  Adds a new rule using a frequency.

  The frequency could be one of: `:secondly`, `:minutely`, `:hourly`, `:daily`, `:weekly`, `:monthly` or `:yearly`.

  ## Options

  - `:interval`: the interval of the frequency (`interval: 2` will generate a `x + n * 2` result)
  - `:hours`: set a restricted on hours of the day (`hours: [20, 10]` will generate every "frequency" at "10:00" and "20:00")

  ## Examples

      iex> add_rule(%ExCycle{rules: []}, :daily, interval: 2, hours: [20, 10])
      %ExCycle.Rule{
        validations: [
          %ExCycle.Validations.HourOfDay{hours: [10, 20]},
          %ExCycle.Validations.Interval{frequency: :daily, value: 2},
          ...
        ],
        ...
      }

  """
  @spec add_rule(t(), ExCycle.Validations.Interval.frequency(), keyword()) :: t()
  def add_rule(%ExCycle{} = cycle, frequency, opts \\ []) do
    Map.update!(cycle, :rules, &(&1 ++ [Rule.new(frequency, opts)]))
  end

  @doc """
  Creates a stream of occurrences using the `from` as reference.

  ## Examples

      iex> cycle =
      ...>   new()
      ...>   |> add_rule(:daily, interval: 2, hours: [20, 10])
      ...>   |> add_rule(:daily, interval: 1, hours: [15])
      ...>   |> occurrences(~D[2024-02-29])
      ...>   |> Enum.take(9)
      [
         ~N[2024-02-29 10:00:00],
         ~N[2024-02-29 15:00:00],
         ~N[2024-02-29 20:00:00],
         ~N[2024-03-01 15:00:00],
         ~N[2024-03-02 10:00:00],
         ~N[2024-03-02 15:00:00],
         ~N[2024-03-02 20:00:00],
         ~N[2024-03-03 15:00:00],
         ~N[2024-03-04 10:00:00]
      ]

  """
  @spec occurrences(t(), datetime()) :: Enumerable.t(NaiveDateTime.t() | ExCycle.Span.t())
  def occurrences(%ExCycle{} = cycle, from) do
    cycle
    |> Map.update!(:rules, fn rules ->
      Enum.map(rules, &Rule.init(&1, from))
    end)
    |> Stream.unfold(&get_next_occurrence/1)
  end

  defp get_next_occurrence(%ExCycle{} = cycle) do
    result =
      cycle.rules
      |> Enum.with_index()
      |> Enum.reject(fn {rule, _index} -> rule.state.exhausted? end)
      |> do_get_next_occurrence()

    with {rule, index} <- result do
      updated_rules = List.update_at(cycle.rules, index, &Rule.next/1)
      {rule.state.result, %{cycle | rules: updated_rules}}
    end
  end

  defp do_get_next_occurrence([]), do: nil

  defp do_get_next_occurrence([default | rules]) do
    Enum.reduce(rules, default, fn {rule, index}, {curr_rule, curr_index} ->
      if datetime_compare(curr_rule.state.result, rule.state.result) == :gt do
        {rule, index}
      else
        {curr_rule, curr_index}
      end
    end)
  end

  # NOTE because state's result could be a NaiveDateTime, DateTime, or a span with NaiveDateTime or DateTime
  # We have to convert everything to a Etc/UTC to compare them and make sure to return the most recent result.
  defp datetime_compare(%ExCycle.Span{from: left}, right) do
    datetime_compare(left, right)
  end

  defp datetime_compare(left, %ExCycle.Span{from: right}) do
    datetime_compare(left, right)
  end

  defp datetime_compare(%NaiveDateTime{} = left, right) do
    datetime_compare(DateTime.from_naive!(left, "Etc/UTC"), right)
  end

  defp datetime_compare(left, %NaiveDateTime{} = right) do
    datetime_compare(left, DateTime.from_naive!(right, "Etc/UTC"))
  end

  defp datetime_compare(left, right) do
    DateTime.compare(left, right)
  end
end
