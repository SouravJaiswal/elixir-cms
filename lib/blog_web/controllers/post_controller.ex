defmodule BlogWeb.PostController do
  use BlogWeb, :controller

  alias Blog.Posts
  alias Blog.Posts.Post
  alias Blog.Documents

  action_fallback(BlogWeb.FallbackController)

  def index(conn, _params) do
    posts = Posts.list_posts()
    render(conn, "index.json", posts: posts)
  end

  def create(conn, post_params) do
    with {:ok, %Post{} = post} <- Posts.create_post(post_params),
         {:ok, _header_image} <-
           Documents.create_upload_from_plug_upload(post, post_params["header_image"]),
         post <-
           Posts.get_post!(post.id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.post_path(conn, :show, post))
      |> render("show.json", post: post)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Posts.get_post!(id)
    render(conn, "show.json", post: post)
  end

  def update(conn, %{"id" => id} = post_params) do
    post = Posts.get_post!(id)

    with {:ok, %Post{} = post} <- Posts.update_post(post, post_params),
         {:ok, _header_image} <-
           Documents.update_upload_from_plug_upload(post, post_params["header_image"]),
         post <-
           Posts.get_post!(id) do
      render(conn, "show.json", post: post)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Posts.get_post!(id)

    with {:ok, _} <- Posts.delete_post(post) do
      send_resp(conn, :no_content, "")
    end
  end
end
