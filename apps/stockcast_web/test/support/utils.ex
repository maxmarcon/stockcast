defmodule StockcastWeb.TestUtils do
  import Phoenix.ConnTest
  use ExUnit.CaseTemplate

  def json_error_response(conn, status_code, detail) do
    json_data = json_response(conn, status_code)

    assert %{
             "status" => %{
               "detail" => ^detail
             }
           } = json_data
  end
end
