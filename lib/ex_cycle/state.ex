defmodule ExCycle.State do
  @moduledoc """
  The `ExCycle.State` represents the state of the next generated datetime.
  """

  alias __MODULE__

  @type t :: %State{
          origin: NaiveDateTime.t(),
          next: NaiveDateTime.t(),
          result: DateTime.t() | NaiveDateTime.t() | ExCycle.Span.t() | nil
        }

  defstruct [:origin, :next, :result]

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
      result: nil
    }
  end

  @doc """
  Resets the state.

  By resetting, we means set the `origin` value equal to `next` value.

  ## Examples

      iex> reset(%ExCycle.State{origin: ~N[2024-03-01 00:00:00], next: ~N[2024-06-01 00:00:00]})
      %ExCycle.State{origin: ~N[2024-06-01 00:00:00], next: ~N[2024-06-01 00:00:00]}

  """
  @spec reset(t()) :: t()
  def reset(state) do
    %{state | origin: state.next}
  end

  @doc """
  `update_next/3` is an helper to update the next value.
  """
  @spec update_next(t(), fun()) :: t()
  def update_next(datetime_state, fun) do
    Map.update!(datetime_state, :next, fun)
  end

  def set_next(state, datetime) do
    %{state | next: to_naive(datetime)}
  end

  def set_result(state) do
    {:ok, %{state | result: state.next}}
  end

  def apply_duration(state, nil), do: {:ok, state}

  def apply_duration(state, duration) do
    {:ok, Map.put(state, :result, ExCycle.Span.new(state.next, duration))}
  end

  def apply_timezone(state, nil), do: {:ok, state}

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def apply_timezone(%{result: %ExCycle.Span{}} = state, timezone) do
    from =
      case DateTime.from_naive(state.result.from, timezone) do
        {:ok, datetime} -> datetime
        {:ambiguous, datetime, _} -> datetime
        {:gap, _, datetime} -> datetime
        {:error, :utc_only_time_zone_database} -> raise "Please use a time zone database"
      end

    to =
      case DateTime.from_naive(state.result.to, timezone) do
        {:ok, datetime} -> datetime
        {:ambiguous, _, datetime} -> datetime
        {:gap, _, datetime} -> datetime
        {:error, :utc_only_time_zone_database} -> raise "Please use a time zone database"
      end

    if DateTime.compare(from, to) == :lt do
      {:ok, Map.update!(state, :result, &%{&1 | from: from, to: to})}
    else
      {:error, state}
    end
  end

  def apply_timezone(state, timezone) do
    case DateTime.from_naive(state.result, timezone) do
      {:ok, datetime} -> {:ok, %{state | result: datetime}}
      _ -> {:error, state}
    end
  end

  defp to_naive(%Date{} = date), do: NaiveDateTime.new!(date, ~T[00:00:00])
  defp to_naive(%DateTime{} = datetime), do: DateTime.to_naive(datetime)
  defp to_naive(%NaiveDateTime{} = datetime), do: datetime
end
