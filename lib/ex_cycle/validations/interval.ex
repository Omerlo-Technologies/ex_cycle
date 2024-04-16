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
    origin_week = Date.beginning_of_week(state.origin)
    next_week = Date.beginning_of_week(state.next)
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
  def next(state, %Interval{frequency: type, value: value} = validation)
      when type in [:hourly, :minutely, :secondly] do
    unit = Map.get(@type_to_unit, type)

    if state.origin == state.next do
      ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, value, unit))
    else
      diff = Map.get(state.next, unit) - Map.get(state.origin, unit)
      ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, value - diff, unit))
    end
  end

  def next(state, %Interval{frequency: :daily, value: value} = validation) do
    if state.origin == state.next do
      ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, value, :day))
    else
      ExCycle.State.update_next(state, validation, fn next ->
        diff_days = Date.diff(state.next, state.origin)
        rem_days = rem(diff_days, value)

        NaiveDateTime.add(next, value - rem_days, :day)
      end)
    end
  end

  def next(state, %Interval{frequency: :weekly, value: value} = validation) do
    if state.origin == state.next do
      ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, value * 7, :day))
    else
      origin_week = Date.beginning_of_week(state.origin)
      next_week = Date.beginning_of_week(state.next)
      diff = rem(Date.diff(next_week, origin_week), value * 7)
      ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, diff, :day))
    end
  end

  def next(state, %Interval{frequency: :monthly, value: value} = validation) do
    months = value + state.origin.month - 1
    shift_years = state.origin.year + div(months, 12)
    shift_months = rem(months, 12) + 1

    ExCycle.State.update_next(state, validation, fn next ->
      %{next | year: shift_years, month: shift_months}
    end)
  end

  def next(state, %Interval{frequency: :yearly, value: value} = validation) do
    ExCycle.State.update_next(state, validation, fn next ->
      diff_years = next.year - state.origin.year
      rem_years = rem(diff_years, value)
      %{next | year: state.origin.year + diff_years + value - rem_years}
    end)
  end
end
