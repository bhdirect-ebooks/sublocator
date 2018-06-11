defmodule Sublocator do
  @moduledoc """
  Documentation for Sublocator.
  """
  alias __MODULE__

  @type t :: %{line: integer, col: integer}
  @type pattern :: binary | list(binary) | Regex.t()
  @type at_most :: :all | integer

  @spec new(integer, integer) :: t
  def new(line, col) when is_integer(line) and is_integer(col) do
    %{line: line, col: col}
  end

  @doc ~S"""
  Finds line and coloumn location(s) of a pattern in a given string.

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
      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", "a", start: %{line: 2, col: 11})
      {:ok, [%{line: 2, col: 11}, %{line: 2, col: 16}]}
  A list of strings:
      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", ["h", "l"])
      {:ok, [%{line: 1, col: 2}, %{line: 2, col: 10}]
  A regular expression:
      iex> Sublocator.locate("<h2>\n  <span class=\"a\"", ~r{<(?!h)})
      {:ok, [%{line: 2, col: 3}]}
  """
  @spec locate(binary, pattern, keyword) :: {atom, list(t) | binary}
  def locate(string, pattern, opts \\ [])

  def locate(string, pattern, opts) when is_binary(string) and is_list(pattern) do
    joined = Enum.map(pattern, &Regex.escape(&1)) |> Enum.join("|")
    regexp = Regex.compile!("(?:#{joined})")
    locate(string, regexp, opts)
  end

  def locate(string, pattern, opts) when is_binary(string) do
    at_most = Keyword.get(opts, :at_most, :all)
    start_loc = Keyword.get(opts, :start, new(0, 0))

    stream_lines(string)
    |> do_locate(pattern, at_most, start_loc)
  end

  def locate(_string, _pattern, _opts), do: {:error, "intended only for a string"}

  defp stream_locations(lines, pattern, start) do
    lines
    |> Stream.flat_map(&locate_inline(&1, pattern, start))
  end

  defp do_locate(lines, pattern, :all, start) do
    locs =
      stream_locations(lines, pattern, start)
      |> Enum.to_list()

    {:ok, locs}
  end

  defp do_locate(_lines, _pattern, cnt, _start) when is_integer(cnt) and cnt <= 0 do
    {:error, ":at_most value must be greater than 0 or :all"}
  end

  defp do_locate(lines, pattern, cnt, start) when is_integer(cnt) do
    locs =
      stream_locations(lines, pattern, start)
      |> Enum.take(cnt)

    {:ok, locs}
  end

  defp stream_lines(string) do
    Regex.split(~r{(?:\r\n|\n|\r)}, string)
    |> Stream.with_index(1)
  end

  @spec locate_inline({binary, integer}, pattern, t) :: list(t)
  defp locate_inline(line_tup, patt, start)

  defp locate_inline({line_str, line}, %Regex{} = patt, %{line: sl, col: sc})
       when line >= sl do
    start_col = if line == sl, do: sc, else: 0

    {matches, non_matches} =
      Regex.split(patt, line_str, include_captures: true)
      |> Enum.split_with(&Regex.match?(patt, &1))

    non_matches
    |> do_inline(matches)
    |> report_locs(line, start_col)
  end

  defp locate_inline({line_str, line}, patt, %{line: sl, col: sc})
       when is_binary(patt) and line >= sl do
    start_col = if line == sl, do: sc, else: 0

    String.split(line_str, patt)
    |> do_inline(String.length(patt))
    |> report_locs(line, start_col)
  end

  defp locate_inline(_line_tup, _patt, _start), do: []

  defp report_locs(hits, line, start_col) do
    hits
    |> Enum.filter(&(&1 >= start_col))
    |> Enum.map(&new(line, &1))
  end

  defp do_inline([h, nh | tail], patt_len) when is_integer(patt_len) do
    col = String.length(h) + 1
    [col] ++ do_inline([nh | tail], patt_len, col)
  end

  defp do_inline([h, nh | tail], matches) do
    col = String.length(h) + 1
    [col] ++ do_inline([nh | tail], matches, col)
  end

  defp do_inline([_], _patt_len), do: []

  defp do_inline([h, nh | tail], patt_len, at_len) when is_integer(patt_len) do
    col = String.length(h)
    [col] ++ do_inline([nh | tail], patt_len, at_len + patt_len + col)
  end

  defp do_inline([h, nh | tail], [first | rest], at_len) do
    col = String.length(h)
    match_len = String.length(first)
    [col] ++ do_inline([nh | tail], rest, at_len + match_len + col)
  end

  defp do_inline([_], _patt_len, _at_len), do: []
end
