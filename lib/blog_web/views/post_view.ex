defmodule BlogWeb.PostView do
  use BlogWeb, :view
  alias Blog.Documents.Upload

  def format_date(date) do
    {:ok, date} = DateTime.from_naive(date, "Etc/UTC")

    Integer.to_string(date.day) <>
      "-" <> Integer.to_string(date.month) <> "-" <> Integer.to_string(date.year)
  end

  def display_brief(body) when byte_size(body) > 100 do
    body = String.slice(body, 0..100) <> "..."
    body
  end

  def display_brief(body) do
    body
  end

  def header_image_url(type, %Blog.Posts.Post{:upload => nil} = _post) do
    header_image(type, nil)
  end

  def header_image_url(type, %Blog.Posts.Post{:upload => upload} = post) do
    case File.stat(Upload.local_path(upload.id, upload.filename)) do
      {:ok, _} ->
        header_image(type, upload)

      {:error, _} ->
        header_image(type, nil)
    end
  end

  defp header_image(:full, %Blog.Documents.Upload{} = upload) do
    BlogWeb.Router.Helpers.static_path(
      BlogWeb.Endpoint,
      "/uploads/" <> "#{upload.id}-#{upload.filename}"
    )
  end

  defp header_image(:thumbnail, %Blog.Documents.Upload{} = upload) do
    BlogWeb.Router.Helpers.static_path(
      BlogWeb.Endpoint,
      "/uploads/" <> "#{upload.id}-timg-#{upload.filename}"
    )
  end

  defp header_image(_, nil) do
    "https://via.placeholder.com/150x75"
  end
end
