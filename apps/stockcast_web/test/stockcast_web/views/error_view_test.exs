defmodule StockcastWeb.ErrorViewTest do
  use StockcastWeb.ConnCase, async: true

  alias StockcastWeb.ErrorView

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders <STATUS>.json with known status" do
    assert render(ErrorView, "404.json", %{}) == %{status: %{detail: "Not Found"}}
  end

  test "render <STATUS>.json with bogus status" do
    assert render(ErrorView, "FOO.json", %{}) == %{
             status: %{
               detail: "Internal Server Error"
             }
           }
  end
end
