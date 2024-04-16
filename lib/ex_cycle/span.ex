defmodule ExCycle.Span do
  @moduledoc false

  alias __MODULE__

  defstruct [:from, :to]

  @type t :: %Span{from: NaiveDateTime.t(), to: NaiveDateTime.t()}

  @spec new(NaiveDateTime.t(), Duration.t()) :: t()
  def new(from, duration) do
    # NOTE RFC doesn't support month and year duration
    from
    |> NaiveDateTime.add(duration.week * 7, :day)
    |> NaiveDateTime.add(duration.day, :day)
    |> NaiveDateTime.add(duration.hour, :hour)
    |> NaiveDateTime.add(duration.minute, :minute)
    |> NaiveDateTime.add(duration.second, :second)
    |> then(&%Span{from: from, to: &1})
  end
end
