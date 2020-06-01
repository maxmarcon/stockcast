defmodule StockcastWeb.PageController do
  use StockcastWeb, :controller

  def app(conn, _params) do
    Plug.Conn.put_resp_content_type(conn, "text/html")
    |> Plug.Conn.send_file(:ok, Application.app_dir(:stockcast_web, "priv/static/index.html"))
  end

  def event(conn, params), do: app(conn, params)
end
