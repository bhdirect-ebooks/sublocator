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

    assert actual == {:ok, [%Sublocator{line: 13, col: 7}]}
  end

  test "locates all regex occurrences", context do
    {:ok, html} = context.test_file

    actual =
      Sublocator.locate(
        html,
        ~r/<span epub:type="pagebreak" id="page\d+" title="\d+"><\/span>/,
        at_most: :all
      )

    assert actual == {:ok, [%Sublocator{line: 13, col: 7}]}
  end
end
