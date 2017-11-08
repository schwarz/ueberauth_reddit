defmodule Ueberauth.Strategy.Reddit do
  @moduledoc """
  Reddit strategy for Überauth.
  """

  use Ueberauth.Strategy, scope: "identity"
  alias Ueberauth.Auth.{Credentials, Info, Extra}
  alias Ueberauth.Strategy.Reddit.OAuth

  @doc """
  Handles initial request for Reddit authentication.
  """
  @spec handle_request!(Plug.Conn.t) :: Plug.Conn.t
  def handle_request!(conn) do
    scopes = conn.params["scope"] || Keyword.get(default_options(), :scope)
    state = conn.params["state"] || random_string(32)
    opts = [
      redirect_uri: callback_url(conn),
      scope: scopes,
      state: state
    ]

    redirect!(conn, Ueberauth.Strategy.Reddit.OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from Reddit.
  """
  @spec handle_callback!(Plug.Conn.t) :: Plug.Conn.t
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    client = Ueberauth.Strategy.Reddit.OAuth.get_token!([code: code, redirect_uri: callback_url(conn)])
    if client.token.access_token == nil do
      err = client.token.other_params["error"]
      desc = client.token.other_params["error_description"]
      set_errors!(conn, [error(err, desc)])
    else
      conn
      |> put_private(:reddit_token, client.token)
      |> fetch_user(client)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  @spec handle_cleanup!(Plug.Conn.t) :: Plug.Conn.t
  def handle_cleanup!(conn) do
    conn
    |> put_private(:reddit_token, nil)
    |> put_private(:reddit_user, nil)
  end

  @spec uid(Plug.Conn.t) :: String.t
  def uid(conn) do
    conn.private.reddit_user["id"]
  end

  @spec credentials(Plug.Conn.t) :: Credentials.t
  def credentials(conn) do
    token = conn.private.reddit_token
    scopes =
      (token.other_params["scope"] || "")
      |> String.split(" ")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @spec info(Plug.Conn.t) :: Info.t
  def info(conn) do
    user = conn.private.reddit_user
    %Info{
      name: user["name"],
      nickname: user["name"]
    }
  end

  @spec extra(Plug.Conn.t) :: Extra.t
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.reddit_token,
        user: conn.private.reddit_user
      }
    }
  end

  defp fetch_user(conn, client) do
    resp = OAuth2.Client.get(client, "/api/v1/me")
    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
        when status_code in 200..399 ->
        put_private(conn, :reddit_user, user)
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  # Taken from Phoenix secret generation task
  defp random_string(length) do
    :crypto.strong_rand_bytes(length) 
    |> Base.encode64() 
    |> binary_part(0, length)
  end

end
