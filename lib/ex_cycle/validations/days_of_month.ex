defmodule ExCycle.Validations.DaysOfMonth do
  @moduledoc """
  DaysOfMonth defines a list of day (number of the day in the month) to use in the generated datetime.

  ## Examples

      iex> %DaysOfMonth{days: [1, 10]}

  will generate datetime every 1st and 10th of the month.

      iex> %DaysOfMonth{days: [-1, 10]}

  will generate datetime every last of month and 10th of the month.

  """

  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys [:days]
  defstruct [:days]

  @type t :: %DaysOfMonth{days: [non_neg_integer(), ...]}

  @spec new([non_neg_integer(), ...]) :: t()
  def new(days_of_month) do
    if !Enum.any?(days_of_month, &valid_day_of_month?/1) do
      raise "Days of month must be contained in [-31;-1] or [1;31]"
    end

    %DaysOfMonth{days: Enum.sort(days_of_month)}
  end

  defp valid_day_of_month?(value) when value > 0 and value <= 31, do: true
  defp valid_day_of_month?(value) when value < 0 and value >= -31, do: true
  defp valid_day_of_month?(_value), do: false

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(state, %DaysOfMonth{days: days}) do
    last_day_of_month = Date.end_of_month(state.next)

    Enum.any?(days, fn
      day when day > 0 -> state.next.day == day
      day when day < 0 -> state.next.day == last_day_of_month.day + day + 1
    end)
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %DaysOfMonth{days: days}) do
    ExCycle.State.update_next(state, fn next ->
      days
      |> get_next_day(next)
      |> NaiveDateTime.new!(~T[00:00:00])
    end)
  end

  defp get_next_day(days, current_day, condition \\ &>/2) do
    last_day_of_month = current_day |> Date.end_of_month() |> Map.get(:day)

    date =
      days
      |> Enum.map(fn
        day when day < 0 -> last_day_of_month + day + 1
        day -> day
      end)
      |> Enum.filter(&Calendar.ISO.valid_date?(current_day.year, current_day.month, &1))
      |> Enum.map(&Date.new!(current_day.year, current_day.month, &1))
      |> Enum.sort()
      |> Enum.find(&condition.(Date.diff(&1, current_day), 0))

    if date do
      date
    else
      current_day
      |> Date.end_of_month()
      |> Date.add(1)
      |> then(fn date -> get_next_day(days, date, &>=/2) end)
    end
  end
end
