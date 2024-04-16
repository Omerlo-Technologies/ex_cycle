defmodule ExCycle.Validations.Lock do
  @moduledoc """
  The `Lock` validation is used to lock a specific item like `:day`.
  So the generated datetime MUST have the valid datetime that match this restriction.
  """

  @behaviour ExCycle.Validations

  alias __MODULE__

  @enforce_keys :unit
  defstruct [:unit]

  @type unit :: :second | :minute | :hour | :day | :week_day | :month
  @type t :: %Lock{unit: unit()}

  @spec new(unit()) :: t()
  def new(unit) do
    %Lock{unit: unit}
  end

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(state, %Lock{unit: unit}) when unit in [:second, :minute, :hour, :month] do
    Map.get(state.origin, unit) == Map.get(state.next, unit)
  end

  def valid?(state, %Lock{unit: :day}) do
    state.origin.day == state.next.day
  end

  def valid?(state, %Lock{unit: :week_day}) do
    Date.day_of_week(state.origin) == Date.day_of_week(state.next)
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %Lock{unit: unit} = validation) when unit in [:second, :minute] do
    diff = Map.get(state.origin, unit) - Map.get(state.next, unit) + 60
    ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, diff, unit))
  end

  def next(state, %Lock{unit: :hour} = validation) do
    diff = state.origin.hour - state.next.hour + 24
    ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, diff, :hour))
  end

  def next(state, %Lock{unit: :day} = validation) do
    shift_years = state.next.year + div(state.next.month, 12)
    shift_months = rem(state.next.month, 12) + 1

    ExCycle.State.update_next(state, validation, fn next ->
      %{next | year: shift_years, month: shift_months, day: state.origin.day}
    end)
  end

  def next(state, %Lock{unit: :month} = validation) do
    ExCycle.State.update_next(state, validation, fn next ->
      %{next | year: next.year + 1, month: state.origin.month}
    end)
  end

  def next(state, %Lock{unit: :week_day} = validation) do
    origin_day_week = Date.day_of_week(state.origin)
    next_day_week = Date.day_of_week(state.next)

    if origin_day_week != next_day_week do
      diff = rem(7 - next_day_week + origin_day_week, 7)
      ExCycle.State.update_next(state, validation, &NaiveDateTime.add(&1, diff, :day))
    else
      state
    end
  end
end
