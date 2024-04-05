defmodule ExCycle.Validations.HourOfDay do
  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys [:hours]
  defstruct hours: []

  @type t :: %HourOfDay{hours: list(non_neg_integer())}

  @spec new(list(non_neg_integer())) :: t()
  def new(hours) do
    invalid_hours = Enum.filter(hours, &(&1 < 0 || &1 > 23))

    unless Enum.empty?(invalid_hours) do
      raise "Invalid hours: #{Enum.join(invalid_hours, ", ")}, must be between 0 and 23"
    end

    %HourOfDay{hours: Enum.sort(hours)}
  end

  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(datetime_state, %HourOfDay{hours: hours}) do
    Enum.any?(hours, &(&1 == datetime_state.next.hour))
  end

  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %HourOfDay{hours: hours}) do
    next_hour = Enum.find(hours, &(&1 >= state.next.hour)) || hd(hours)
    diff = rem(next_hour - state.next.hour, 24)

    ExCycle.State.update_next(state, &NaiveDateTime.add(&1, diff, :hour))
  end
end
