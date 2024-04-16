defmodule ExCycle.Rule do
  @moduledoc """
  Representation of a RRule following RFC 5455 (not fully compatible for the moment).
  """

  alias __MODULE__
  alias ExCycle.Validations

  @type t :: %Rule{
          validations: [Validations.any_validation(), ...],
          state: ExCycle.State.t() | nil,
          count: non_neg_integer() | nil,
          until: Date.t() | nil
        }

  defstruct validations: [], count: nil, until: nil, state: nil

  @doc """
  Defines a new Rule struct.

  ## Examples

      iex> new(:daily, hours: [20, 10])
      %ExCycle.Rule{
        validations: [
          %ExCycle.Validations.HourOfDay{hours: [10, 20]},
          %ExCycle.Validations.Interval{frequency: :daily, value: 1},
          %ExCycle.Validations.DateValidation{},
          %ExCycle.Validations.Lock{unit: :minute},
          %ExCycle.Validations.Lock{unit: :second}
        ],
        count: nil,
        until: nil,
        state: nil
      }

  """
  @spec new(Validations.Interval.frequency(), keyword()) :: t()
  def new(frequency, opts \\ []) do
    opts = Keyword.new(opts)

    {count, opts} = Keyword.pop(opts, :count, nil)
    {until, opts} = Keyword.pop(opts, :until, nil)
    {interval, opts} = Keyword.pop(opts, :interval, 1)

    opts = Keyword.put(opts, frequency, interval)

    %Rule{
      validations: Validations.build(frequency, opts),
      count: count,
      until: until
    }
  end

  @doc """

  Returns the next dates that match validations.

  ## Examples

      iex> rule =
      ...>   Rule.new(:daily, interval: 2, hours: [20, 10])
      ...>   |> Map.put(:state, ExCycle.State.new(~D[2024-04-04]))

      iex> rule = Rule.next(rule)
      %Rule{state: %ExCycle.State{next: ~N[2024-04-04 10:00:00]}}

      iex> rule = Rule.next(rule)
      %Rule{state: %ExCycle.State{next: ~N[2024-04-04 20:00:00]}}

  """
  @spec next(t()) :: ExCycle.State.t()
  def next(%Rule{} = rule) do
    %mod{} = first_validation = hd(rule.validations)

    Map.update!(rule, :state, fn state ->
      state
      |> ExCycle.State.reset()
      |> mod.next(first_validation)
      |> do_next(rule.validations)
    end)
  end

  defp do_next(state, validations) do
    case Enum.find(validations, &invalid?(state, &1)) do
      %mod{} = invalid_validation ->
        state
        |> mod.next(invalid_validation)
        |> do_next(validations)

      nil ->
        state
    end
  end

  defp invalid?(state, %mod{} = validation) do
    !mod.valid?(state, validation)
  end
end
