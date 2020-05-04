defmodule StockcastWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use StockcastWeb, :controller

  def call(conn, {:error, reason_atom}) when is_atom(reason_atom) do
    code = Plug.Conn.Status.code(reason_atom)

    conn
    |> put_status(reason_atom)
    |> put_view(StockcastWeb.ErrorView)
    |> render("#{code}.json", %{})
  end
end
