defmodule ExCycle.Validations.Interval do
  @behaviour ExCycle.Validations

  alias __MODULE__

  @type t :: %Interval{type: interval_type, value: non_neg_integer()}
  @type interval_type :: :secondly | :minutely | :hourly | :daily | :weekly | :monthly | :yearly

  defstruct [:type, value: 1]

  @type_to_unit %{daily: :day, hourly: :hour, minutely: :minute, secondly: :second}

  @spec new(interval_type(), non_neg_integer()) :: t()
  def new(interval_type, value) do
    unless interval_type in [:secondly, :minutely, :hourly, :daily, :weekly, :monthly, :yearly] do
      raise "invalid type: #{interval_type}, must be one of secondly, minutely, hourly, daily, weekly, monthly or yearly"
    end

    unless value > 0 do
      raise "invalid value, must be higher or equal to 1"
    end

    %Interval{type: interval_type, value: value}
  end

  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(_state, %Interval{value: 1}), do: true

  def valid?(state, %{type: type, value: value})
      when type in [:daily, :hourly, :minutely, :secondly] do
    unit = Map.get(@type_to_unit, type)
    diff = NaiveDateTime.diff(state.origin, state.next, unit)
    rem(diff, value) == 0
  end

  def valid?(state, %{type: :weekly, value: value}) do
    origin_week = Date.beginning_of_week(state.origin)
    next_week = Date.beginning_of_week(state.next)
    diff = Date.diff(origin_week, next_week)
    rem(diff, value * 7) == 0
  end

  def valid?(state, %{type: :monthly, value: value}) do
    origin_months = state.origin.year * 12 + state.origin.month
    next_months = state.next.year * 12 + state.next.month
    diff = origin_months - next_months
    rem(diff, value) == 0
  end

  def valid?(state, %{type: :yearly, value: value}) do
    rem(state.origin.year - state.next.year, value) == 0
  end

  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %Interval{type: type, value: value})
      when type in [:daily, :hourly, :minutely, :secondly] do
    unit = Map.get(@type_to_unit, type)
    ExCycle.State.update_next(state, &NaiveDateTime.add(&1, value, unit))
  end

  def next(state, %Interval{type: :weekly, value: value}) do
    ExCycle.State.update_next(state, &NaiveDateTime.add(&1, 7 * value, :day))
  end

  def next(state, %Interval{type: :monthly, value: value}) do
    ExCycle.State.update_next(state, fn next ->
      months = value + next.month - 1
      shift_years = next.year + div(months, 12)
      shift_months = rem(months, 12) + 1

      %{next | year: shift_years, month: shift_months}
      |> ensure_valid_date()
    end)
  end

  def next(state, %Interval{type: :yearly, value: value}) do
    ExCycle.State.update_next(state, fn next ->
      %{next | year: next.year + value}
      |> ensure_valid_date()
    end)
  end

  defp ensure_valid_date(datetime) do
    if Calendar.ISO.valid_date?(datetime.year, datetime.month, datetime.day) do
      datetime
    else
      datetime
      |> Date.end_of_month()
      |> NaiveDateTime.new!(NaiveDateTime.to_time(datetime))
    end
  end
end
