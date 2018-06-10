defmodule SublocatorTest do
  use ExUnit.Case
  doctest Sublocator

  setup_all do
    %{test_file: File.read("test/ActsExe102_body02_chapter01.xhtml")}
  end

  test "returns empty list for no occurrence", context do
    {:ok, html} = context.test_file
    actual = Sublocator.locate(html, "p class=\"survival\"", at_most: 99)

    assert actual == {:ok, []}
  end

  test "locates first substring occurrence", context do
    {:ok, html} = context.test_file
    actual = Sublocator.locate(html, "<h2", at_most: 1)

    assert actual == {:ok, [%Sublocator{line: 13, col: 7}]}
  end

  test "locates all substring occurrences", context do
    {:ok, html} = context.test_file
    actual = Sublocator.locate(html, "<h2", at_most: :all)

    assert actual ==
             {:ok,
              [
                %Sublocator{line: 13, col: 7},
                %Sublocator{line: 18, col: 7},
                %Sublocator{line: 26, col: 7},
                %Sublocator{line: 73, col: 7},
                %Sublocator{line: 121, col: 7},
                %Sublocator{line: 142, col: 7},
                %Sublocator{line: 163, col: 7},
                %Sublocator{line: 185, col: 7},
                %Sublocator{line: 200, col: 7}
              ]}
  end

  test "locates with simple regex pattern" do
    actual = Sublocator.locate("dswuuhå∂œ¥éüüu", ~r/é/, at_most: :all)
    assert actual === {:ok, [%Sublocator{line: 1, col: 11}]}
  end

  test "locates all regex occurrences", context do
    {:ok, html} = context.test_file

    actual =
      Sublocator.locate(
        html,
        ~r/<span epub:type="pagebreak" id="page\d+" title="\d+"><\/span>/,
        at_most: :all
      )

    assert actual ==
             {:ok,
              [
                %Sublocator{line: 9, col: 34},
                %Sublocator{line: 20, col: 167},
                %Sublocator{line: 23, col: 425},
                %Sublocator{line: 31, col: 182},
                %Sublocator{line: 35, col: 7},
                %Sublocator{line: 40, col: 603},
                %Sublocator{line: 43, col: 1073},
                %Sublocator{line: 45, col: 1289},
                %Sublocator{line: 48, col: 10},
                %Sublocator{line: 51, col: 1735},
                %Sublocator{line: 55, col: 7},
                %Sublocator{line: 60, col: 628},
                %Sublocator{line: 66, col: 339},
                %Sublocator{line: 69, col: 1348},
                %Sublocator{line: 75, col: 10},
                %Sublocator{line: 78, col: 682},
                %Sublocator{line: 84, col: 10},
                %Sublocator{line: 86, col: 174},
                %Sublocator{line: 90, col: 603},
                %Sublocator{line: 96, col: 10},
                %Sublocator{line: 102, col: 10},
                %Sublocator{line: 108, col: 10},
                %Sublocator{line: 112, col: 348},
                %Sublocator{line: 118, col: 686},
                %Sublocator{line: 122, col: 481},
                %Sublocator{line: 128, col: 10},
                %Sublocator{line: 133, col: 936},
                %Sublocator{line: 140, col: 170},
                %Sublocator{line: 147, col: 629},
                %Sublocator{line: 150, col: 7},
                %Sublocator{line: 156, col: 10},
                %Sublocator{line: 161, col: 7},
                %Sublocator{line: 169, col: 639},
                %Sublocator{line: 175, col: 301},
                %Sublocator{line: 178, col: 7},
                %Sublocator{line: 186, col: 178},
                %Sublocator{line: 190, col: 489},
                %Sublocator{line: 196, col: 311},
                %Sublocator{line: 201, col: 341},
                %Sublocator{line: 813, col: 7}
              ]}
  end
end
