defmodule SublocatorTest do
  use ExUnit.Case
  doctest Sublocator

  setup_all do
    %{test_file: File.read("test/PrideAndPrejudice.html")}
  end

  test "creates a new location map" do
    assert Sublocator.new_loc(2, 4) === %{line: 2, col: 4}
  end

  test "accepts only a string as primary parameter" do
    assert Sublocator.locate(:html, "h", at_most: 0) === {:error, "intended only for a string"}
  end

  test "returns error for bad :at_most value" do
    assert Sublocator.locate("html", "h", at_most: 0) ===
             {:error, ":at_most value must be greater than 0 or :all"}
  end

  test "returns empty list for no occurrence", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, "p class=\"survival\"", at_most: 99)

    assert actual === []
  end

  test "locates first substring occurrence", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, "<h2", at_most: 1)

    assert actual === [%{line: 22, col: 1}]
  end

  test "locates all substring occurrences", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, "<h2", at_most: :all)

    assert actual ===
             [
               %{line: 22, col: 1},
               %{line: 101, col: 1},
               %{line: 141, col: 1},
               %{line: 174, col: 1},
               %{line: 200, col: 1},
               %{line: 222, col: 1},
               %{line: 251, col: 1},
               %{line: 327, col: 1},
               %{line: 381, col: 1},
               %{line: 446, col: 1},
               %{line: 491, col: 1},
               %{line: 579, col: 1},
               %{line: 619, col: 1},
               %{line: 682, col: 1},
               %{line: 712, col: 1},
               %{line: 769, col: 1},
               %{line: 828, col: 1},
               %{line: 894, col: 1},
               %{line: 938, col: 1},
               %{line: 1014, col: 1},
               %{line: 1095, col: 1},
               %{line: 1127, col: 1},
               %{line: 1179, col: 1},
               %{line: 1250, col: 1},
               %{line: 1285, col: 1},
               %{line: 1327, col: 1},
               %{line: 1367, col: 1},
               %{line: 1380, col: 1},
               %{line: 1417, col: 1},
               %{line: 1440, col: 1},
               %{line: 1459, col: 1},
               %{line: 1539, col: 1},
               %{line: 1560, col: 1},
               %{line: 1638, col: 1},
               %{line: 1681, col: 1},
               %{line: 1717, col: 1},
               %{line: 1754, col: 1},
               %{line: 1778, col: 1},
               %{line: 1809, col: 1},
               %{line: 1862, col: 1},
               %{line: 1888, col: 1},
               %{line: 1923, col: 1},
               %{line: 1952, col: 1},
               %{line: 1978, col: 1},
               %{line: 2042, col: 1},
               %{line: 2060, col: 1},
               %{line: 2096, col: 1},
               %{line: 2133, col: 1},
               %{line: 2180, col: 1},
               %{line: 2233, col: 1},
               %{line: 2252, col: 1},
               %{line: 2271, col: 1},
               %{line: 2297, col: 1},
               %{line: 2320, col: 1},
               %{line: 2368, col: 1},
               %{line: 2409, col: 1},
               %{line: 2456, col: 1},
               %{line: 2479, col: 1},
               %{line: 2578, col: 1},
               %{line: 2602, col: 1},
               %{line: 2628, col: 1},
               %{line: 2663, col: 1}
             ]
  end

  test "locates a given number of substring occurrences after a point", context do
    {:ok, html} = context.test_file

    {:ok, actual} = Sublocator.locate(html, "<h2", at_most: 1, start: %{line: 2180, col: 2})

    assert actual === [%{line: 2233, col: 1}]
  end

  test "locates many substring occurrences", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, "the")

    assert Enum.count(actual) === 7449
  end

  test "locates a more particular substring", context do
    {:ok, html} = context.test_file

    {:ok, actual} =
      Sublocator.locate(
        html,
        "It needed all Jane's steady mildness to bear these attacks with tolerable tranquillity."
      )

    assert actual === [%{line: 1792, col: 484}]
  end

  test "locates a list of substrings", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, ["class=", "<h2"])

    assert Enum.count(actual) === 186 + 62
  end

  test "locates with simple regex pattern" do
    {:ok, actual} = Sublocator.locate("dswuuhå∂œ¥éüüu", ~r{é}, at_most: :all)
    assert actual === [%{line: 1, col: 11}]
  end

  test "locates all regex matches", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, ~r{<i>.*?</i>})

    assert Enum.count(actual) === 404
  end

  test "locates regex matches after a given start point", context do
    {:ok, html} = context.test_file

    {:ok, actual} =
      Sublocator.locate(html, ~r{<i>[^<]+</i>}, at_most: 6, start: %{line: 1440, col: 200})

    assert actual === [
             %{line: 1443, col: 187},
             %{line: 1443, col: 634},
             %{line: 1443, col: 743},
             %{line: 1443, col: 781},
             %{line: 1462, col: 1122},
             %{line: 1472, col: 29}
           ]
  end

  test "locates a number of regex matches", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, ~r{id="pgepubid\d+"}, at_most: 2)

    assert actual === [%{line: 20, col: 5}, %{line: 101, col: 5}]
  end
end
