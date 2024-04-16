defmodule ExCycle.State do
  @moduledoc false

  alias __MODULE__

  @type t :: %State{
          origin: NaiveDateTime.t(),
          next: NaiveDateTime.t(),
          validations: []
        }

  defstruct [:origin, :next, validations: []]

  @type datetime :: Date.t() | DateTime.t() | NaiveDateTime.t()

  @doc """
  Creates a new state.
  The `next` dates will be the same as `origin`.

  ## Examples

      iex> new(~D[2024-01-01])
      %ExCycle.State{origin: ~N[2024-01-01 00:00:00], next: ~N[2024-01-01 00:00:00]}

      iex> new(~N[2024-01-01 10:00:00])
      %ExCycle.State{origin: ~N[2024-01-01 10:00:00], next: ~N[2024-01-01 10:00:00]}

  """
  @spec new(datetime()) :: t()
  def new(origin \\ NaiveDateTime.utc_now()) do
    new(origin, origin)
  end

  @doc """
  Creates a new state specifying the `origin` and the `next` (aka `from` is this context).

  ## Examples

      iex> new(~D[2024-01-01], ~D[2024-02-02])
      %ExCycle.State{origin: ~N[2024-01-01 00:00:00], next: ~N[2024-02-02 00:00:00]}

      iex> new(~N[2024-01-01 10:00:00], ~D[2024-02-02])
      %ExCycle.State{origin: ~N[2024-01-01 10:00:00], next: ~N[2024-02-02 00:00:00]}

      iex> new(~N[2024-01-01 10:00:00], ~N[2024-02-02 10:00:00])
      %ExCycle.State{origin: ~N[2024-01-01 10:00:00], next: ~N[2024-02-02 10:00:00]}

  """
  @spec new(datetime(), datetime()) :: t()
  def new(origin, from) do
    %State{
      origin: to_naive(origin),
      next: to_naive(from),
      validations: []
    }
  end

  @doc """
  Resets the state.

  By resetting, we means set `validations` to empty list and set the `origin` value equal to `next` value.

  ## Examples

      iex> reset(%ExCycle.State{origin: ~N[2024-03-01 00:00:00], next: ~N[2024-06-01 00:00:00], validations: [...]})
      %ExCycle.State{origin: ~N[2024-06-01 00:00:00], next: ~N[2024-06-01 00:00:00], validations: []}

  """
  @spec reset(t()) :: t()
  def reset(state) do
    %{state | origin: state.next, validations: []}
  end

  @doc """
  `update_next/3` is an helper to update the next value and add the `validation` applied to the list
  of `validations` of the state.
  """
  @spec update_next(t(), ExCycle.Validations.any_validation(), fun()) :: t()
  def update_next(datetime_state, validation, fun) do
    state = Map.update!(datetime_state, :next, fun)

    Map.update!(
      state,
      :validations,
      &[%{validation: validation, state: Map.take(state, [:origin, :next])} | &1]
    )
  end

  defp to_naive(%Date{} = date), do: NaiveDateTime.new!(date, ~T[00:00:00])
  defp to_naive(%DateTime{} = datetime), do: DateTime.to_naive(datetime)
  defp to_naive(%NaiveDateTime{} = datetime), do: datetime
end
