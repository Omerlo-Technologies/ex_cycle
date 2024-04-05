defmodule ExCycle.State do
  @moduledoc false

  alias __MODULE__

  @type t :: %State{
          origin: NaiveDateTime.t(),
          next: NaiveDateTime.t()
        }

  defstruct [:origin, :next]

  def new(origin \\ NaiveDateTime.utc_now(), from \\ NaiveDateTime.utc_now()) do
    %State{
      origin: to_naive(origin),
      next: to_naive(from)
    }
  end

  @spec update_next(t(), fun()) :: t()
  def update_next(datetime_state, fun) do
    Map.update!(datetime_state, :next, fun)
  end

  defp to_naive(%Date{} = date), do: NaiveDateTime.new!(date, ~T[00:00:00])
  defp to_naive(%DateTime{} = datetime), do: DateTime.to_naive(datetime)
  defp to_naive(%NaiveDateTime{} = datetime), do: datetime
end
