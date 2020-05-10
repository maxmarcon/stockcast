defmodule StockcastWeb.TestUtils do
  import Phoenix.ConnTest
  use ExUnit.CaseTemplate

  def json_error_response(conn, status_code, detail) do
    json_data = json_response(conn, status_code)

    assert %{
             "status" => %{
               "error" => Plug.Conn.Status.reason_phrase(status_code),
               "detail" => detail
             }
           } == json_data
  end

  def json_error_response(conn, status_code) do
    json_data = json_response(conn, status_code)

    assert %{
             "status" => %{
               "error" => Plug.Conn.Status.reason_phrase(status_code)
             }
           } == json_data
  end
end
