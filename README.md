# Überauth Reddit

[![Hex.pm](https://img.shields.io/hexpm/v/ueberauth_reddit.svg)](https://hex.pm/packages/ueberauth_reddit)

> Reddit OAuth2 strategy for Überauth.

## Installation

1. Setup your application on [Reddit](https://www.reddit.com/prefs/apps/).

1. Add `:ueberauth_reddit` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_reddit, "~> 0.2"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_reddit]]
    end
    ```

1. Add Reddit to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        reddit: {Ueberauth.Strategy.Reddit, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Reddit.OAuth,
      client_id: System.get_env("REDDIT_CLIENT_ID"),
      client_secret: System.get_env("REDDIT_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/reddit

Or with options:

    /auth/reddit?scope=identity

By default the requested scope is "identity". The scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    reddit: {Ueberauth.Strategy.Reddit, [scope: "identity"]}
  ]
```

Available scopes are: `identity`, `edit`, `flair`, `history`, `modconfig`, `modflair`, `modlog`, `modposts`, `modwiki`, `mysubreddits`, `privatemessages`, `read`, `report`, `save`, `submit`, `subscribe`, `vote`, `wikiedit`, `wikiread`.

## License

Please see [LICENSE](https://github.com/schwarz/ueberauth_reddit/blob/master/LICENSE) for licensing details.
