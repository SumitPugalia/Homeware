defmodule HomeWareWeb.Router do
  use HomeWareWeb, :router

  def fetch_current_user(conn, opts),
    do: HomeWareWeb.UserAuthGuardian.fetch_current_user(conn, opts)

  def require_authenticated_user(conn, opts),
    do: HomeWareWeb.UserAuthGuardian.require_authenticated_user(conn, opts)

  def require_admin_user(conn, opts),
    do: HomeWareWeb.UserAuthGuardian.require_admin_user(conn, opts)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HomeWareWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug HomeWareWeb.Plugs.NavCounts
  end

  pipeline :require_auth do
    plug :require_authenticated_user
  end

  pipeline :require_admin do
    plug :require_authenticated_user
    plug :require_admin_user
  end

  scope "/", HomeWareWeb do
    pipe_through :browser

    get "/", PageController, :home
    post "/cart/add", CartController, :add_to_cart

    # Static pages (public)
    get "/about", PageController, :about
    get "/contact", PageController, :contact
    post "/contact/submit", PageController, :contact_submit
    get "/shipping", PageController, :shipping
    get "/returns", PageController, :returns
    get "/privacy", PageController, :privacy
    get "/terms", PageController, :terms

    # Authentication routes
    get "/signup", UserRegistrationController, :new
    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    delete "/users/log_out", UserSessionController, :delete
    live "/chat", ChatLive
  end

  # Protected LiveView routes
  scope "/", HomeWareWeb do
    pipe_through [:browser, :require_auth]

    live "/products", ProductCatalogLive, :index
    live "/products/:id", ProductDetailLive, :show
    live "/categories", CategoryIndexLive, :index
    live "/categories/:id", CategoryShowLive, :show
    live "/search", SearchLive, :index

    # Cart and checkout
    live "/checkout", CheckoutLive, :index
  end

  # Protected routes
  scope "/", HomeWareWeb do
    pipe_through [:browser, :require_auth]

    get "/profile", UserController, :profile
    get "/profile/edit", UserController, :edit
    put "/profile", UserController, :update
    get "/orders", OrderController, :index
    get "/orders/:id", OrderController, :show
    live "/wishlist", WishlistLive, :index
    live "/account", AccountLive, :index

    # Addresses
    resources "/addresses", AddressController
  end

  # Admin routes
  scope "/admin", HomeWareWeb.Admin, as: :admin do
    pipe_through [:browser, :require_admin]

    live "/dashboard", DashboardLive, :index

    get "/products/:id/confirm_delete", ProductController, :confirm_delete,
      as: :product_confirm_delete

    resources "/products", ProductController, except: [:show] do
      resources "/variants", ProductVariantController, except: [:show]
    end

    resources "/orders", OrderController, only: [:index, :show]
    post "/orders/:id/update_status", OrderController, :update_status

    # resources "/categories", CategoryController
    # resources "/users", UserController
    live "/chat", ChatLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", HomeWareWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:home_ware, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HomeWareWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
