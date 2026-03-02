defmodule DittoWeb.Router do
  use DittoWeb, :router

  import DittoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DittoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_org_access do
    plug :verify_organization_access
  end

  pipeline :require_sysadmin_access do
    plug :ensure_sysadmin
  end

  scope "/", DittoWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", DittoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ditto, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DittoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", DittoWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{DittoWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/welcome", WelcomeLive, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", DittoWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{DittoWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
    end

    post "/users/register", UserRegistrationController, :create
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Organization-scoped routes

  scope "/orgs/:org", DittoWeb do
    pipe_through [:browser, :require_authenticated_user, :require_org_access]

    live_session :org_authenticated,
      on_mount: [
        {DittoWeb.UserAuth, :require_authenticated},
        {DittoWeb.UserAuth, :verify_organization_access}
      ] do
      live "/dashboard", OrgLive.Dashboard, :index
      live "/members", OrgLive.Members, :index
      live "/settings", OrgLive.Settings, :edit
    end
  end

  ## Sysadmin routes

  scope "/sysadmin", DittoWeb do
    pipe_through [:browser, :require_authenticated_user, :require_sysadmin_access]

    live_session :sysadmin,
      on_mount: [
        {DittoWeb.UserAuth, :require_authenticated},
        {DittoWeb.UserAuth, :require_sysadmin}
      ] do
      live "/", SysadminLive.Dashboard, :index
      live "/organizations", SysadminLive.Organizations, :index
    end
  end
end
