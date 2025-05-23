defmodule ExCycle.Validations.Days do
  @moduledoc """
  Days defines a list of day (day in the week, like monday, tuesday ...) to use in the generated time.

  ## Examples

      iex> %Days{days: [:monday]}
      # will generate datetimes every monday

      iex> %Days{days_by_week: [{-1, :monday}, {2, :saturday}]}
      # will generate datetimes every last monday and every second saturday of the month

      iex> %Days{days: [:monday], days_by_week: [{1, :tuesday}]}
      # Will generate datetimes every monday and every first tuesday of the month

  """

  @behaviour ExCycle.Validations
  @behaviour ExCycle.StringBuilder

  alias __MODULE__

  @enforce_keys [:days, :days_by_week]
  defstruct [:days, :days_by_week]

  @type day :: :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type week :: integer()

  @type t :: %Days{days: [day()], days_by_week: [{integer(), day()}]}

  @spec new([{week(), day()} | day()]) :: t()
  def new(days) do
    %{true: days_by_week, false: days} =
      days
      |> Enum.group_by(&is_tuple/1)
      |> Enum.into(%{true: [], false: []})

    days_by_week =
      days_by_week
      |> Enum.reject(fn {_week, day} -> day in days end)
      |> Enum.sort_by(fn
        {week, day} when week < 0 -> {week + 100, day_number(day)}
        {week, day} -> {week, day_number(day)}
      end)

    days = Enum.sort_by(days, &day_number/1)

    if Enum.any?(days_by_week, fn {week, _day} -> week < -5 || week > 5 || week == 0 end) do
      raise "Week must be between 1 and 5 OR between -5 and -1"
    end

    %Days{days: days, days_by_week: days_by_week}
  end

  @impl ExCycle.Validations
  @spec valid?(ExCycle.State.t(), t()) :: boolean()
  def valid?(state, %Days{days: days, days_by_week: days_by_week}) do
    Enum.any?(days, &valid_day?(state.next, &1)) ||
      Enum.any?(days_by_week, &valid_day?(state.next, &1))
  end

  @impl ExCycle.Validations
  @spec next(ExCycle.State.t(), t()) :: ExCycle.State.t()
  def next(state, %Days{days: days, days_by_week: days_by_week}) do
    origin_date = NaiveDateTime.to_date(state.next)
    next_date = get_next_date(origin_date, days)
    next_date_by_week = get_next_date_by_week(origin_date, days_by_week)

    cond do
      is_nil(next_date) -> next_date_by_week
      is_nil(next_date_by_week) -> next_date
      Date.compare(next_date, next_date_by_week) == :lt -> next_date
      true -> next_date_by_week
    end
    |> NaiveDateTime.new!(~T[00:00:00])
    |> then(&ExCycle.State.set_next(state, &1))
  end

  defp get_next_date(date, days) do
    curr_day_of_week = Date.day_of_week(date)
    next_day = Enum.find(days, &(day_number(&1) > curr_day_of_week)) || List.first(days)

    if next_day do
      next_day_of_week = day_number(next_day)
      diff = rem(next_day_of_week - curr_day_of_week + 7, 7)

      if diff == 0 do
        Date.add(date, 7)
      else
        Date.add(date, diff)
      end
    end
  end

  defp get_next_date_by_week(date, days_by_week) do
    dates =
      Enum.map(days_by_week, fn
        {week, week_day} when week < 0 ->
          do_get_next_date_by_week(date, {week, week_day}, &Date.end_of_month/1)

        {week, week_day} ->
          do_get_next_date_by_week(date, {week - 1, week_day}, &Date.beginning_of_month/1)
      end)

    unless Enum.empty?(dates) do
      Enum.min_by(dates, &Date.to_iso8601/1)
    end
  end

  defp do_get_next_date_by_week(date, {week, week_day}, shift) do
    from = shift.(date)
    do_get_next_date_by_week(date, {week, week_day}, from, shift)
  end

  defp do_get_next_date_by_week(date, {week, week_day}, from, shift) do
    curr_week_day = Date.day_of_week(from)
    diff_week_day = rem(day_number(week_day) - curr_week_day + 7, 7)
    delta_week = if diff_week_day == 0 and week < 0, do: 1, else: 0
    next_date = Date.add(from, 7 * (week + delta_week) + diff_week_day)

    if Date.compare(date, next_date) == :lt do
      next_date
    else
      new_from =
        from
        |> Date.end_of_month()
        |> Date.add(1)
        |> shift.()

      do_get_next_date_by_week(date, {week, week_day}, new_from, shift)
    end
  end

  defp valid_day?(datetime, {week, day}) when week < 0 do
    day_number = day_number(day)
    curr_day_of_week = Date.day_of_week(datetime)
    curr_week = week_of_month(datetime)
    last_day = Date.end_of_month(datetime)
    total_weeks = week_of_month(last_day)

    first_day_of_last_week_number = last_day |> Date.beginning_of_week() |> Date.day_of_week()
    last_day_number = Date.day_of_week(last_day)

    if day_number <= last_day_number && day_number >= first_day_of_last_week_number do
      total_weeks + 1 + week == curr_week && curr_day_of_week == day_number
    else
      total_weeks + week == curr_week && curr_day_of_week == day_number
    end
  end

  defp valid_day?(datetime, {week, day}) do
    day_number = day_number(day)
    datetime_week = week_of_month(datetime)
    first_day_number = datetime |> Date.beginning_of_month() |> Date.day_of_week()

    last_day_of_first_week_number =
      datetime |> Date.beginning_of_month() |> Date.end_of_week() |> Date.day_of_week()

    if day_number >= first_day_number && day_number <= last_day_of_first_week_number do
      week == datetime_week && Date.day_of_week(datetime) == day_number
    else
      week + 1 == datetime_week && Date.day_of_week(datetime) == day_number
    end
  end

  defp valid_day?(datetime, day) do
    Date.day_of_week(datetime) == day_number(day)
  end

  defp week_of_month(date) do
    first_of_month = Date.beginning_of_month(date)
    first_of_month_day_number = Date.day_of_week(first_of_month)
    div(date.day + first_of_month_day_number - 2, 7) + 1
  end

  @day %{monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6, sunday: 7}
  defp day_number(day), do: Map.fetch!(@day, day)

  @impl ExCycle.StringBuilder
  def string_params(%Days{} = days) do
    days_params = Enum.map(days.days, &{to_string(&1), []})
    days_by_week_params = Enum.map(days.days_by_week, &day_by_week_string_params/1)

    {:days, :lists.append(days_params, days_by_week_params)}
  end

  defp day_by_week_string_params({1, day}), do: {"first %{day}", day: day}
  defp day_by_week_string_params({2, day}), do: {"second %{day}", day: day}
  defp day_by_week_string_params({3, day}), do: {"third %{day}", day: day}
  defp day_by_week_string_params({4, day}), do: {"fourth %{day}", day: day}
  defp day_by_week_string_params({5, day}), do: {"fifth %{day}", day: day}
  defp day_by_week_string_params({-1, day}), do: {"last %{day}", day: day}
  defp day_by_week_string_params({-2, day}), do: {"second to last %{day}", day: day}
  defp day_by_week_string_params({-3, day}), do: {"third to last %{day}", day: day}
  defp day_by_week_string_params({-4, day}), do: {"fourth to last %{day}", day: day}
  defp day_by_week_string_params({-5, day}), do: {"fifth to last %{day}", day: day}
end
