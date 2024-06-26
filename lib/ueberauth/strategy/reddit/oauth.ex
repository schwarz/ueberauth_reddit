defmodule Ueberauth.Strategy.Reddit.OAuth do
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://oauth.reddit.com",
    authorize_url: "https://www.reddit.com/api/v1/authorize",
    token_url: "https://www.reddit.com/api/v1/access_token",
    user_agent: "Uberauth-Reddit:#{Mix.Project.config()[:version]}"
  ]

  @config Application.compile_env(:ueberauth, Ueberauth.Strategy.Reddit.OAuth, [])

  # Public API
  @spec client(Keyword.t()) :: OAuth2.Client.t()
  def client(opts \\ []) do
    json_library = Ueberauth.json_library()

    @defaults
    |> Keyword.merge(@config)
    |> Keyword.merge(opts)
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
    |> put_user_agent()
  end

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> OAuth2.Client.get_token!(params)
    |> put_user_agent()
  end

  # Strategy Callbacks
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("Accept", "application/json")
    |> basic_auth()
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp put_user_agent(client) do
    user_agent = Keyword.get(@config, :user_agent, @defaults[:user_agent])
    put_header(client, "User-Agent", user_agent)
  end
end
