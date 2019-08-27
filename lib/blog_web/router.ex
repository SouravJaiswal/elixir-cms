defmodule BlogWeb.Router do
  use BlogWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", BlogWeb do
    pipe_through(:api)

    resources("/posts", PostController, except: [:new, :edit])
  end
end
