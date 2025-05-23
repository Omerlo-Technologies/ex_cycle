defmodule ExCycle.Rule do
  @moduledoc """
  Representation of a RRule following RFC 5455 (not fully compatible for the moment).
  """

  alias __MODULE__
  alias ExCycle.Validations

  @type t :: %Rule{
          validations: [Validations.any_validation(), ...],
          state: ExCycle.State.t() | nil,
          timezone: String.t() | nil,
          count: non_neg_integer() | nil,
          until: Date.t() | nil,
          duration: Duration.t() | nil
        }

  defstruct validations: [], count: nil, until: nil, state: nil, duration: nil, timezone: nil

  @doc """
  Defines a new Rule struct.

  ## Options

  - `duration`: a simple `Duration` struct.
  - `count`: the maximum number of recurrences to generate (default: `nil`).
  - `until`: the end date and time for the recurrence. If an occurrence coincides exactly with the `until` timestamp,
    it will be included in the set of generated occurrences.
  - `interval`: base interval of the recurren rule (daily, weekly ....).
  - `start_at`: Reference date to used to every recurrent event generated.
  - `timezone`: TimeZone to use when generating recurrent dates.

  ## Examples

      iex> new(:daily, hours: [20, 10])
      %ExCycle.Rule{
        validations: [
          %ExCycle.Validations.HourOfDay{hours: [10, 20]},
          %ExCycle.Validations.Interval{frequency: :daily, value: 1},
          %ExCycle.Validations.DateValidation{},
          %ExCycle.Validations.Lock{unit: :minute},
          %ExCycle.Validations.Lock{unit: :second}
        ],
        timezone: nil,
        count: nil,
        until: nil,
        state: %ExCycle.State{}
      }

      iex> new(:daily, hours: [20, 10], starts_at: ~N[2024-04-22 17:00:00], timezone: "America/Montreal")
      %ExCycle.Rule{
        validations: [
          %ExCycle.Validations.HourOfDay{hours: [10, 20]},
          %ExCycle.Validations.Interval{frequency: :daily, value: 1},
          %ExCycle.Validations.DateValidation{},
          %ExCycle.Validations.Lock{unit: :minute},
          %ExCycle.Validations.Lock{unit: :second}
        ],
        timezone: "America/Montreal",
        count: nil,
        until: nil,
        state: %ExCycle.State{starts_at: ~N[2024-04-22 17:00:00]}
      }

  """
  @spec new(Validations.Interval.frequency(), keyword()) :: t()
  def new(frequency, opts \\ []) do
    opts = Keyword.new(opts)

    {duration, opts} = Keyword.pop(opts, :duration, nil)
    {count, opts} = Keyword.pop(opts, :count, nil)
    {until, opts} = Keyword.pop(opts, :until, nil)
    {interval, opts} = Keyword.pop(opts, :interval, 1)
    {start_at, opts} = Keyword.pop(opts, :starts_at)
    {timezone, opts} = Keyword.pop(opts, :timezone)

    opts =
      opts
      |> Keyword.update(:excluded_dates, [], &cast_excluded_dates(&1, timezone))
      |> Keyword.put(frequency, interval)

    %Rule{
      state: if(start_at, do: ExCycle.State.new(start_at)),
      timezone: timezone,
      validations: Validations.build(frequency, opts),
      count: count,
      until: until,
      duration: if(valid_duration?(duration), do: duration)
    }
  end

  defp valid_duration?(duration) do
    case duration do
      %Duration{} ->
        duration
        |> Map.take([:week, :day, :hour, :minute, :second])
        |> Enum.any?(fn {_unit, value} -> value != 0 end)

      _ ->
        false
    end
  end

  @doc """
  Initializes the rule starting from the `from` datetime.

  ## Examples

      iex> init(%Rule{}, ~D[2024-01-01])
      %ExCycle{}

      iex> init(%Rule{}, ~N[2024-01-01 10:00:00])
      %ExCycle{}

  """
  @spec init(t(), ExCycle.datetime(), keyword()) :: t()
  def init(rule, from, opts \\ []) do
    week_starting_on = Keyword.get(opts, :week_starting_on, :default)

    rule
    |> Map.update!(:state, fn state ->
      (state || ExCycle.State.new(from))
      |> ExCycle.State.init(from)
      |> ExCycle.State.set_week_starting_on(week_starting_on)
      |> do_next(rule.validations)
    end)
    |> generate_result()
  end

  @doc """

  Returns the next dates that match validations.

  ## Examples

      iex> rule =
      ...>   Rule.new(:daily, interval: 2, hours: [20, 10])
      ...>   |> Map.put(:state, ExCycle.State.new(~D[2024-04-04]))
      ...> rule = Rule.next(rule)
      %Rule{state: %ExCycle.State{next: ~N[2024-04-04 10:00:00]}}

  """
  @spec next(t()) :: t()
  def next(%Rule{} = rule) do
    %mod{} = first_validation = hd(rule.validations)

    rule
    |> Map.update!(:state, fn state ->
      state
      |> Map.put(:origin, state.next)
      |> mod.next(first_validation)
      |> do_next(rule.validations)
    end)
    |> generate_result()
  end

  defp generate_result(rule) do
    with {:ok, state} <- ExCycle.State.set_result(rule.state),
         {:ok, state} <- ExCycle.State.apply_duration(state, rule.duration),
         {:ok, state} <- ExCycle.State.apply_timezone(state, rule.timezone),
         {:ok, state} <- ExCycle.State.check_exhaust(state, rule.until),
         {:ok, state} <- ExCycle.State.check_exhaust(state, rule.count) do
      Map.put(rule, :state, state)
    else
      {:exhausted, state} ->
        Map.put(rule, :state, %{state | exhausted?: true})

      {:error, state} ->
        rule
        |> Map.put(:state, %{state | origin: state.next})
        |> next()
    end
  end

  defp do_next(state, validations) do
    state = ExCycle.State.ensure_valid(state)

    case Enum.find(validations, &invalid?(state, &1)) do
      %mod{} = invalid_validation ->
        state
        |> mod.next(invalid_validation)
        |> do_next(validations)

      nil ->
        state
    end
  end

  defp invalid?(state, %mod{} = validation) do
    !mod.valid?(state, validation)
  end

  defp cast_excluded_dates(dates, timezone) do
    Enum.map(dates, &cast_excluded_date(&1, timezone))
  end

  defp cast_excluded_date(%DateTime{} = datetime, timezone) do
    if timezone do
      datetime
      |> DateTime.shift_zone!(timezone)
      |> DateTime.to_naive()
    else
      DateTime.to_naive(datetime)
    end
  end

  defp cast_excluded_date(date, _timezone), do: date
end
