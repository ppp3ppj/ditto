defmodule DittoWeb.PageController do
  use DittoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
