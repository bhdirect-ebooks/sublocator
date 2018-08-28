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
    |> intersperse(pattern)
    |> do_locate(pattern, at_most, start_loc)
  end

  def locate(_string, _pattern, _opts), do: {:error, "intended only for a string"}

  @spec intersperse(Enumerable.t(binary), pattern) :: Enumerable.t(binary)
  defp intersperse(split_result, pattern)

  defp intersperse(split_result, pattern) when is_binary(pattern) do
    Enum.intersperse(split_result, pattern)
  end

  defp intersperse(split_result, _pattern), do: split_result

  @spec stream_lines(binary) :: Enumerable.t({binary, integer})
  defp stream_lines(string) do
    ~r{(?:\r\n|\n|\r)}
    |> Regex.split(string)
    |> Stream.with_index(@col_offset)
  end

  @spec stream_locations(Enumerable.t(binary), pattern, t) :: Enumerable.t(t)
  defp stream_locations(lines, pattern, start) do
    lines
    |> Stream.flat_map(&locate_inline(&1, pattern, start))
  end

  @spec stream_parts(Enumerable.t(binary), pattern, t) :: Enumerable.t(t)
  defp stream_parts(parts, pattern, start) do
    parts
    |> Stream.flat_map(&report_locs(&1, pattern, start))
  end

  @spec do_locate(Enumerable.t(), pattern, at_most, t) :: {atom, list(t) | binary}
  defp do_locate(parts, pattern, cnt, start)

  defp do_locate(parts, pattern, :all, %{line: line, col: col} = start) when is_loc(line, col) do
    locs =
      parts
      |> stream_parts(pattern, start)
      |> Enum.to_list()

    {:ok, locs}
  end

  defp do_locate(_parts, _pattern, cnt, _start) when is_integer(cnt) and cnt <= 0 do
    {:error, ":at_most value must be greater than 0 or :all"}
  end

  defp do_locate(parts, pattern, cnt, %{line: line, col: col} = start)
       when is_integer(cnt) and is_loc(line, col) do
    locs =
      parts
      |> stream_parts(pattern, start)
      |> Enum.take(cnt)

    {:ok, locs}
  end

  defp do_locate(_parts, _pattern, cnt, _start) when not is_integer(cnt) and cnt != :all do
    {:error, ":at_most value must be an integer or :all"}
  end

  defp do_locate(_parts, _pattern, _cnt, _start) do
    {:error, ":start value must be %{line: integer, col: integer}"}
  end

  @spec do_regex_split(Regex.t(), binary) :: {list(binary), list(binary)}
  defp do_regex_split(patt, line_str) do
    patt
    |> Regex.split(line_str, include_captures: true)
    |> Enum.split_with(&Regex.match?(patt, &1))
  end

  @spec locate_inline({binary, integer}, pattern, t) :: list(t)
  defp locate_inline(line_tup, patt, start)

  defp locate_inline({line_str, line}, %Regex{} = patt, %{line: sl, col: sc})
       when line >= sl do
    start_col = if line == sl, do: sc, else: 0
    {matches, non_matches} = do_regex_split(patt, line_str)

    non_matches
    |> do_inline(matches)
    |> report_locs(line, start_col)
  end

  defp locate_inline({line_str, line}, patt, %{line: sl, col: sc})
       when is_binary(patt) and line >= sl do
    start_col = if line == sl, do: sc, else: 0

    line_str
    |> String.split(patt)
    |> do_inline(String.length(patt))
    |> report_locs(line, start_col)
  end

  defp locate_inline(_line_tup, _patt, _start), do: []

  @spec do_inline(list(binary), integer | list(binary)) :: list(integer)
  defp do_inline([h, nh | tail], patt_len) when is_integer(patt_len) do
    col = String.length(h) + @col_offset
    [col] ++ do_inline([nh | tail], patt_len, col)
  end

  defp do_inline([h, nh | tail], matches) do
    col = String.length(h) + @col_offset
    [col] ++ do_inline([nh | tail], matches, col)
  end

  defp do_inline([_], _patt_len), do: []

  @spec do_inline(list(binary), integer | list(binary), integer) :: list(integer)
  defp do_inline([h, nh | tail], patt_len, at_len) when is_integer(patt_len) do
    col = String.length(h) + patt_len + at_len
    [col] ++ do_inline([nh | tail], patt_len, col)
  end

  defp do_inline([h, nh | tail], [first | rest], at_len) do
    col = String.length(h) + String.length(first) + at_len
    [col] ++ do_inline([nh | tail], rest, col)
  end

  defp do_inline([_], _patt_len, _at_len), do: []

  @spec report_locs(list(integer), integer, integer) :: list(t)
  defp report_locs(hits, line, start_col) do
    hits
    |> Enum.filter(&(&1 >= start_col))
    |> Enum.map(&new_loc(line, &1))
  end
end
