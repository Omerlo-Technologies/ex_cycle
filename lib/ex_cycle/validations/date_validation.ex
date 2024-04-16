defmodule ExCycle.Validations.DateValidation do
  @moduledoc false
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
  def next(state, %DateValidation{} = validation) do
    ExCycle.State.update_next(state, validation, fn next ->
      next
      |> Date.end_of_month()
      |> NaiveDateTime.new!(NaiveDateTime.to_time(next))
    end)
  end
end
