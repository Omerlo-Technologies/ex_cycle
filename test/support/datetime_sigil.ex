defmodule ExCycle.Support.DateTimeSigil do
  @moduledoc """
  Test helper sigil for defining DateTimes with zones

  > This code was copied from [cocktail](https://github.com/peek-travel/cocktail/blob/0.10.3/test/support/datetime_sigil.ex)

  """

  def sigil_Y(string, []) do
    [date, time, tz] = String.split(string, " ")

    "#{date} #{time}"
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!(tz)
  end
end
