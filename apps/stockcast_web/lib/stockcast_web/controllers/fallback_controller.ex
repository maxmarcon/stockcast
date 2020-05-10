defmodule StockcastWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use StockcastWeb, :controller

  def call(conn, {:error, reason_atom}) when is_atom(reason_atom) do
    render_response(conn, reason_atom)
  end

  def call(conn, {:error, reason_atom, detail}) when is_atom(reason_atom) and is_atom(detail) do
    call(conn, {:error, reason_atom, Atom.to_string(detail)})
  end

  def call(conn, {:error, reason_atom, detail}) when is_atom(reason_atom) and is_binary(detail) do
    formatted_detail =
      detail
      |> String.replace("_", " ")
      |> String.capitalize()

    render_response(conn, reason_atom, %{detail: formatted_detail})
  end

  defp render_response(conn, reason_atom, assigns \\ %{}) do
    code = Plug.Conn.Status.code(reason_atom)

    conn
    |> put_status(reason_atom)
    |> put_view(StockcastWeb.ErrorView)
    |> render("#{code}.json", assigns)
  end
end
