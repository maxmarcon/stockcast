defmodule StockcastWeb.ErrorView do
  use StockcastWeb, :view

  def render(<<status::binary-size(3), ".json">>, %{}) do
    status =
      case Integer.parse(status) do
        {numeric_status, _} -> numeric_status
        _ -> 500
      end

    %{status: status, message: Plug.Conn.Status.reason_phrase(status)}
  end

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
