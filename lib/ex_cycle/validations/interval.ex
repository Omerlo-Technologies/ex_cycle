defmodule ExCycle.Validations.Interval do
  @moduledoc """
  Interval is the base of RRule. Every Rule could be:

  - `secondly`
  - `minutely`
  - `hourly`
  - `daily`
  - `weekly`
  - `montly`
  - `yearly`

  """

  @behaviour ExCycle.Validations
  @behaviour ExCycle.StringBuilder

  alias __MODULE__

  @type t :: %Interval{frequency: frequency, value: non_neg_integer()}
  @type frequency :: :secondly | :minutely | :hourly | :daily | :weekly | :monthly | :yearly

  defstruct [:frequency, value: 1]

  @type_to_unit %{daily: :day, hourly: :hour, minutely: :minute, secondly: :second}

  @frequencies [:secondly, :minutely, :hourly, :daily, :weekly, :monthly, :yearly]

  @spec new(frequency(), non_neg_integer()) :: t()
  def new(frequency, value \\ 1) do
    unless frequency in @frequencies do
      raise "invalid frequency: #{frequency}, must be one of secondly, minutely, hourly, daily, weekly, monthly or yearly"
    end

    unless value > 0 do
      raise "invalid value, must be higher or equal to 1"
    end

    %Interval{frequency: frequency, value: value}
  end

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(_state, %Interval{value: 1}), do: true

  def valid?(state, %{frequency: type, value: value})
      when type in [:hourly, :minutely, :secondly] do
    unit = Map.get(@type_to_unit, type)
    diff = NaiveDateTime.diff(state.next, state.origin, unit)
    rem(diff, value) == 0
  end

  def valid?(state, %{frequency: :daily, value: value}) do
    diff = Date.diff(state.next, state.origin)
    rem(diff, value) == 0
  end

  def valid?(state, %{frequency: :weekly, value: value}) do
    origin_week = Date.beginning_of_week(state.origin, state.week_starting_on)
    next_week = Date.beginning_of_week(state.next, state.week_starting_on)
    diff = Date.diff(next_week, origin_week)
    rem(diff, value * 7) == 0
  end

  def valid?(state, %{frequency: :monthly, value: value}) do
    origin_months = state.origin.year * 12 + state.origin.month
    next_months = state.next.year * 12 + state.next.month
    diff = origin_months - next_months
    rem(diff, value) == 0
  end

  def valid?(state, %{frequency: :yearly, value: value}) do
    rem(state.origin.year - state.next.year, value) == 0
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %Interval{frequency: type, value: value})
      when type in [:hourly, :minutely, :secondly] do
    unit = Map.get(@type_to_unit, type)

    if state.origin == state.next do
      ExCycle.State.update_next(state, &NaiveDateTime.add(&1, value, unit))
    else
      diff = Map.get(state.next, unit) - Map.get(state.origin, unit)
      ExCycle.State.update_next(state, &NaiveDateTime.add(&1, value - diff, unit))
    end
  end

  def next(state, %Interval{frequency: :daily, value: value}) do
    if state.origin == state.next do
      ExCycle.State.update_next(state, &NaiveDateTime.add(&1, value, :day))
    else
      ExCycle.State.update_next(state, fn next ->
        diff_days = Date.diff(state.next, state.origin)
        rem_days = rem(diff_days, value)

        NaiveDateTime.add(next, value - rem_days, :day)
      end)
    end
  end

  def next(state, %Interval{frequency: :weekly, value: value}) do
    origin_week = Date.beginning_of_week(state.origin, state.week_starting_on)
    next_week = Date.beginning_of_week(state.next, state.week_starting_on)
    diff = rem(Date.diff(next_week, origin_week), value * 7)
    ExCycle.State.update_next(state, &NaiveDateTime.add(&1, value * 7 - diff, :day))
  end

  def next(state, %Interval{frequency: :monthly, value: value}) do
    diff = state.origin.month - (state.next.month + 12)
    value = value + rem(diff, value)

    months = value + state.next.month - 1
    shift_years = state.next.year + div(months, 12)
    shift_months = rem(months, 12) + 1

    ExCycle.State.update_next(state, fn next ->
      Date.new!(shift_years, shift_months, 1)
      |> NaiveDateTime.new!(NaiveDateTime.to_time(next))
    end)
  end

  def next(state, %Interval{frequency: :yearly, value: value}) do
    ExCycle.State.update_next(state, fn next ->
      diff_years = next.year - state.origin.year
      rem_years = rem(diff_years, value)
      %{next | year: state.origin.year + diff_years + value - rem_years}
    end)
  end

  @impl ExCycle.StringBuilder
  def string_params(%Interval{} = interval) do
    {:interval, [frequency_to_string(interval.value, interval.frequency)]}
  end

  defp frequency_to_string(1, interval), do: {to_string(interval), []}
  defp frequency_to_string(n, :secondly), do: {"every %{n} seconds", [n: n]}
  defp frequency_to_string(n, :minutely), do: {"every %{n} minutes", [n: n]}
  defp frequency_to_string(n, :hourly), do: {"every %{n} hours", [n: n]}
  defp frequency_to_string(n, :daily), do: {"every %{n} days", [n: n]}
  defp frequency_to_string(n, :weekly), do: {"every %{n} weeks", [n: n]}
  defp frequency_to_string(n, :monthly), do: {"every %{n} months", [n: n]}
  defp frequency_to_string(n, :yearly), do: {"every %{n} years", [n: n]}
end
