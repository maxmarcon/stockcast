defmodule Stockcast.IexCloud.Api do
  use Tesla

  require Logger

  plug(Tesla.Middleware.BaseUrl, base_url())
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Query, token: api_token())

  plug(Tesla.Middleware.Headers, [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ])

  @spec get_data(binary(), keyword()) :: any()
  def get_data(path, query \\ []) when is_binary(path),
    do: call_api_and_parse_response(:get, path, query)

  @spec call_api_and_parse_response(atom(), binary(), keyword()) :: any()
  def call_api_and_parse_response(method, path, query) when is_atom(method) and is_binary(path) do
    case request(method: method, url: path, query: query) do
      {:ok, %{status: status, body: body}} when status >= 200 and status < 300 ->
        {:ok, body}

      {:ok, %{body: body}} ->
        {:error, body}

      error ->
        error
    end
  end

  defp api_token() do
    Access.get(Application.get_env(:stockcast, __MODULE__, []), :api_token) ||
      raise "You need to specify a token for the IexCloud API"
  end

  defp base_url() do
    Access.get(Application.get_env(:stockcast, __MODULE__, []), :base_url) ||
      raise "You need to specify an endpoint for the IexCloud API"
  end
end
