defmodule Sublocator do
  @moduledoc """
  Documentation for Sublocator.
  """
  alias __MODULE__

  defstruct line: 0, col: 0

  @type t :: %Sublocator{line: integer, col: integer}
  @type pattern :: binary | Regex.t()
  @type at_most :: :all | integer

  @spec new(integer, integer) :: t
  def new(line, col) when is_integer(line) and is_integer(col) do
    %Sublocator{line: line, col: col}
  end

  @spec locate(binary, pattern, keyword) :: {atom, list(t) | binary}
  def locate(string, pattern, opts \\ [])

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

  defp locate_inline({line_str, line}, %Regex{} = patt, %Sublocator{line: sl, col: sc})
       when line >= sl do
    start_col = if line == sl, do: sc, else: 0

    {matches, non_matches} =
      Regex.split(patt, line_str, include_captures: true)
      |> Enum.split_with(&Regex.match?(patt, &1))

    non_matches
    |> do_inline(matches)
    |> report_locs(line, start_col)
  end

  defp locate_inline({line_str, line}, patt, %Sublocator{line: sl, col: sc})
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
