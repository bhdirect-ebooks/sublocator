defmodule Sublocator do
  @moduledoc """
  An Elixir library for identifying the location(s) of a pattern in a given string.

  Using `Sublocator.locate/3`, the pattern can be a string, a list of strings, or
  a regular expression, and the result is a list of simple line and column data or
  an empty list.
  """
  alias __MODULE__

  @col_offset 1

  @typep t :: %{line: integer, col: integer}
  @typep pattern :: binary | list(binary) | Regex.t()
  @typep at_most :: :all | integer

  defguardp is_loc(line, col) when is_integer(line) and is_integer(col)

  @doc """
  Creates a simple location map from line and column integers.

  ## Example
      iex> Sublocator.new_loc(42, 12)
      %{line: 42, col: 12}
  """
  @spec new_loc(integer, integer) :: t
  def new_loc(line, col) when is_loc(line, col) do
    %{line: line, col: col}
  end

  @doc ~S"""
  Finds line and column location(s) of a pattern in a given string.

  Returns a list of these locations or an empty list if not found.
  The pattern can be a string, a list of strings, or a regular
  expression.

  The returned locations are listed in the order found, from top to
  bottom, left to right.

  All locations are reported in the list by default but can be
  controlled via the `:at_most` option.

  By default, the pattern is located from the beginning of the string,
  but the `:start` option can be used to report locations starting at
  a later point.

  ## Options
    * `:at_most` (positive integer or `:all`) - the number of locations
      returned is at most as many as this option specifies.
      If `:all`, all found locations are returned. Defaults to `:all`.

    * `:start` (`%{line: integer, col: integer}`) - only locations >= the
      starting point specified by this option are returned; otherwise,
      the string is searched from the beginning.

  ## Examples
  Locating with a string:
      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", "a")
      {:ok, [%{line: 2, col: 6}, %{line: 2, col: 11}, %{line: 2, col: 16}]}

      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", "a", at_most: 1)
      {:ok, [%{line: 2, col: 6}]}

      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", "a", [start: %{line: 2, col: 10}])
      {:ok, [%{line: 2, col: 11}, %{line: 2, col: 16}]}

  A list of strings:
      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", ["h", "l"])
      {:ok, [%{line: 1, col: 2}, %{line: 2, col: 10}]}

  A regular expression:
      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", ~r{<(?!h)})
      {:ok, [%{line: 2, col: 3}]}
  """
  @spec locate(binary, pattern, keyword) :: {atom, list(t) | binary}
  def locate(string, pattern, opts \\ [])

  def locate(string, pattern, opts) when is_binary(string) and is_list(pattern) do
    joined =
      pattern
      |> Enum.map(&Regex.escape(&1))
      |> Enum.join("|")

    regexp = Regex.compile!("(?:#{joined})")
    locate(string, regexp, opts)
  end

  def locate(string, pattern, opts) when is_binary(string) do
    at_most = Keyword.get(opts, :at_most, :all)
    start_loc = Keyword.get(opts, :start, new_loc(0, 0))

    string
    |> String.split(pattern, include_captures: true)
    |> tuplify(pattern)
    |> do_locate(at_most, start_loc)
  end

  def locate(_string, _pattern, _opts), do: {:error, "intended only for a string"}

  @spec tuplify(Enumerable.t(binary), pattern) :: Enumerable.t()
  defp tuplify(split_result, pattern)

  defp tuplify(split_result, pattern) when is_binary(pattern) do
    Enum.intersperse(split_result, pattern)
    |> Enum.chunk_every(2, 2, :discard)
    |> Enum.map(&List.to_tuple/1)
  end

  defp tuplify(split_result, _pattern) do
    Enum.chunk_every(split_result, 2, 2, :discard)
    |> Enum.map(&List.to_tuple/1)
  end

  @spec stream_lines(binary) :: Enumerable.t({binary, integer})
  def stream_lines(string) do
    ~r{(?:\r\n|\n|\r)}
    |> Regex.split(string)
    |> Stream.with_index(@col_offset)
  end

  @spec do_locate(Enumerable.t(), at_most, t) :: {atom, list(t) | binary}
  defp do_locate(parts, cnt, start)

  defp do_locate(parts, :all, %{line: line, col: col} = start) when is_loc(line, col) do
    locs =
      parts
      |> report_locs(start)
      |> Enum.to_list()

    {:ok, locs}
  end

  defp do_locate(_parts, cnt, _start) when is_integer(cnt) and cnt <= 0 do
    {:error, ":at_most value must be greater than 0 or :all"}
  end

  defp do_locate(parts, cnt, %{line: line, col: col} = start)
       when is_integer(cnt) and is_loc(line, col) do
    locs =
      parts
      |> report_locs(start)
      |> Enum.take(cnt)

    {:ok, locs}
  end

  defp do_locate(_parts, cnt, _start) when not is_integer(cnt) and cnt != :all do
    {:error, ":at_most value must be an integer or :all"}
  end

  defp do_locate(_parts, _cnt, _start) do
    {:error, ":start value must be %{line: integer, col: integer}"}
  end

  defp get_begin_loc(%{begin_loc: begin_loc}), do: begin_loc

  defp include_loc?(loc, start) do
    col_predicate = if loc.line === start.line, do: loc.col >= start.col, else: true
    loc.line >= start.line && col_predicate
  end

  @spec report_locs(Enumerable.t(binary), t) :: Enumerable.t(t)
  defp report_locs(parts, start) do
    acc = %{begin_loc: new_loc(0, 0), end_loc: new_loc(1, 0)}

    parts
    |> Stream.scan(acc, &report_loc(&2, &1))
    |> Stream.map(&get_begin_loc/1)
    |> Stream.filter(&include_loc?(&1, start))
  end

  @spec report_loc(%{begin_loc: t, end_loc: t}, {binary, binary}) :: %{begin_loc: t, end_loc: t}
  defp report_loc(acc, {before, match}) do
    %{line: blines, col: bcol} = get_partial_loc(before)
    %{line: mlines, col: mcol} = get_partial_loc(match)

    begin_line = blines - 1 + acc.end_loc.line
    begin_col = if begin_line === acc.end_loc.line, do: bcol + acc.end_loc.col, else: bcol
    begin_loc = new_loc(begin_line, begin_col + @col_offset)

    end_line = begin_line + mlines - 1
    end_col = if end_line === begin_line, do: begin_col + mcol, else: mcol
    end_loc = new_loc(end_line, end_col)

    %{begin_loc: begin_loc, end_loc: end_loc}
  end

  @spec get_partial_loc(binary) :: t
  defp get_partial_loc(str) do
    stream_lines(str)
    |> safe_drop(1)
    |> Enum.at(0)
    |> line_info_to_loc()
  end

  @spec safe_drop(Enumerable.t(), integer) :: Enumerable.t()
  defp safe_drop(list, cnt) do
    dropped = Enum.drop(list, cnt)
    if dropped == [], do: list, else: dropped
  end

  @spec line_info_to_loc({binary, integer}) :: t
  defp line_info_to_loc(tup) do
    {str, line} = tup
    new_loc(line, String.length(str))
  end
end
