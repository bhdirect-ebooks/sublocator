defmodule SublocatorTest do
  use ExUnit.Case
  doctest Sublocator

  setup_all do
    %{test_file: File.read("test/ActsExe102_body02_chapter01.xhtml")}
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

    assert actual === [%{line: 13, col: 7}]
  end

  test "locates all substring occurrences", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, "<h2", at_most: :all)

    assert actual ===
             [
               %{line: 13, col: 7},
               %{line: 18, col: 7},
               %{line: 26, col: 7},
               %{line: 73, col: 7},
               %{line: 121, col: 7},
               %{line: 142, col: 7},
               %{line: 163, col: 7},
               %{line: 185, col: 7},
               %{line: 200, col: 7}
             ]
  end

  test "locates a given number of substring occurrences after a point", context do
    {:ok, html} = context.test_file

    {:ok, actual} = Sublocator.locate(html, "<h2", at_most: 1, start: %{line: 121, col: 8})

    assert actual === [%{line: 142, col: 7}]
  end

  test "locates many substring occurrences", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, "epub:type")

    assert Enum.count(actual) === 449
  end

  test "locates a more particular substring", context do
    {:ok, html} = context.test_file

    {:ok, actual} =
      Sublocator.locate(
        html,
        "see Brown, <span class=\"italic\">Communication</span>, 35n16, 46–47.</span>"
      )

    assert actual === [%{line: 582, col: 687}]
  end

  test "locates a list of substrings", context do
    {:ok, html} = context.test_file
    {:ok, actual} = Sublocator.locate(html, ["epub:type", "<h2"])

    assert Enum.count(actual) === 458
  end

  test "locates with simple regex pattern" do
    {:ok, actual} = Sublocator.locate("dswuuhå∂œ¥éüüu", ~r{é}, at_most: :all)
    assert actual === [%{line: 1, col: 11}]
  end

  test "locates all regex matches", context do
    {:ok, html} = context.test_file

    {:ok, actual} =
      Sublocator.locate(
        html,
        ~r{<span epub:type="pagebreak" id="page\d+" title="\d+"></span>},
        at_most: :all
      )

    assert actual ===
             [
               %{line: 9, col: 34},
               %{line: 20, col: 167},
               %{line: 23, col: 425},
               %{line: 31, col: 182},
               %{line: 35, col: 7},
               %{line: 40, col: 603},
               %{line: 43, col: 1073},
               %{line: 45, col: 1289},
               %{line: 48, col: 10},
               %{line: 51, col: 1735},
               %{line: 55, col: 7},
               %{line: 60, col: 628},
               %{line: 66, col: 339},
               %{line: 69, col: 1348},
               %{line: 75, col: 10},
               %{line: 78, col: 682},
               %{line: 84, col: 10},
               %{line: 86, col: 174},
               %{line: 90, col: 603},
               %{line: 96, col: 10},
               %{line: 102, col: 10},
               %{line: 108, col: 10},
               %{line: 112, col: 348},
               %{line: 118, col: 686},
               %{line: 122, col: 481},
               %{line: 128, col: 10},
               %{line: 133, col: 936},
               %{line: 140, col: 170},
               %{line: 147, col: 629},
               %{line: 150, col: 7},
               %{line: 156, col: 10},
               %{line: 161, col: 7},
               %{line: 169, col: 639},
               %{line: 175, col: 301},
               %{line: 178, col: 7},
               %{line: 186, col: 178},
               %{line: 190, col: 489},
               %{line: 196, col: 311},
               %{line: 201, col: 341},
               %{line: 813, col: 7}
             ]
  end

  test "locates regex matches after a given start point", context do
    {:ok, html} = context.test_file

    {:ok, actual} =
      Sublocator.locate(
        html,
        ~r{<span epub:type="pagebreak" id="page\d+" title="\d+"></span>},
        at_most: :all,
        start: %{line: 175, col: 302}
      )

    assert actual === [
             %{line: 178, col: 7},
             %{line: 186, col: 178},
             %{line: 190, col: 489},
             %{line: 196, col: 311},
             %{line: 201, col: 341},
             %{line: 813, col: 7}
           ]
  end

  test "locates a number of regex matches", context do
    {:ok, html} = context.test_file

    {:ok, actual} =
      Sublocator.locate(
        html,
        ~r{<sup class="fn" id="note-backlink-[^"]+">},
        at_most: 2
      )

    assert actual === [%{line: 19, col: 488}, %{line: 20, col: 277}]
  end
end
