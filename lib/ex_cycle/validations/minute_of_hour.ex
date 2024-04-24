defmodule ExCycle.Validations.MinuteOfHour do
  @moduledoc """
  MinuteOfHour defines a list of specific minutes to use in the generated datetime.

  ## Examples

      iex> %MinuteOfHour{minutes: [0, 15, 30, 45]}

  will generate datetime hour at XX:00, XX:15, XX:30 and XX:45.

  """

  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys [:minutes]
  defstruct minutes: []

  @type t :: %MinuteOfHour{minutes: list(non_neg_integer())}

  @spec new(list(non_neg_integer())) :: t()
  def new(minutes) do
    invalid_minutes = Enum.filter(minutes, &(&1 < 0 || &1 > 59))

    unless Enum.empty?(invalid_minutes) do
      raise "Invalid minutes: #{Enum.join(invalid_minutes, ", ")}, must be between 0 and 23"
    end

    %MinuteOfHour{minutes: Enum.sort(minutes)}
  end

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(datetime_state, %MinuteOfHour{minutes: minutes}) do
    Enum.any?(minutes, &(&1 == datetime_state.next.minute))
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %MinuteOfHour{minutes: minutes}) do
    next_minute = Enum.find(minutes, &(&1 > state.next.minute)) || hd(minutes)

    if state.next.minute == next_minute do
      ExCycle.State.update_next(state, &NaiveDateTime.add(&1, 1, :hour))
    else
      diff = rem(next_minute - state.next.minute + 60, 60)
      ExCycle.State.update_next(state, &NaiveDateTime.add(&1, diff, :minute))
    end
  end
end
