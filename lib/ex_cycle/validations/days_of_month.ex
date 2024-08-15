defmodule ExCycle.Validations.DaysOfMonth do
  @moduledoc """
  DaysOfMonth defines a list of day (number of the day in the month) to use in the generated datetime.

  ## Examples

      iex> %DaysOfMonth{days: [1, 10]}

  will generate datetime every 1st and 10th of the month.

  """

  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys [:days]
  defstruct [:days]

  @type t :: %DaysOfMonth{days: [non_neg_integer(), ...]}

  @spec new([non_neg_integer(), ...]) :: t()
  def new(days_of_month) do
    if Enum.any?(days_of_month, &(&1 > 31 || &1 < 1)) do
      raise "Days of month must be less or equal to 31 and more or equal to 1"
    end

    %DaysOfMonth{days: Enum.sort(days_of_month)}
  end

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(state, %DaysOfMonth{days: days}) do
    state.next.day in days
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %DaysOfMonth{days: days}) do
    next_day = Enum.find(days, &(&1 > state.next.day)) || hd(days)

    if next_day > Date.days_in_month(state.next) || next_day <= state.next.day do
      shift_years = state.next.year + div(state.next.month, 12)
      shift_months = rem(state.next.month, 12) + 1

      ExCycle.State.update_next(state, fn next ->
        %{next | year: shift_years, month: shift_months, day: next_day}
        |> NaiveDateTime.to_date()
        |> NaiveDateTime.new!(~T[00:00:00])
      end)
    else
      ExCycle.State.update_next(state, fn next ->
        NaiveDateTime.to_date(next)
        |> Map.put(:day, next_day)
        |> NaiveDateTime.new!(~T[00:00:00])
      end)
    end
  end
end
