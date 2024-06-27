defmodule ExCycle.Validations.DateValidation do
  @moduledoc """
  `DateValidation` ensure the generated date is a valid dates.
  This is usefull for leap year and not leap year (e.g. 2023-02-29 doesn't exist wheras 2024-02-29 do).
  """
  @behaviour ExCycle.Validations

  alias __MODULE__

  defstruct []

  @type t :: %DateValidation{}

  @spec new() :: t()
  def new() do
    %DateValidation{}
  end

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(state, %DateValidation{}) do
    Calendar.ISO.valid_date?(state.next.year, state.next.month, state.next.day)
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %DateValidation{}) do
    ExCycle.State.update_next(state, fn next ->
      next
      |> Date.end_of_month()
      |> Date.add(1)
      |> NaiveDateTime.new!(NaiveDateTime.to_time(next))
    end)
  end
end
