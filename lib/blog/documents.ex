defmodule Blog.Documents do
  @moduledoc """
  The Documents context.
  """

  import Ecto.Query, warn: false
  alias Blog.Repo

  alias Blog.Documents.Upload
  import Mogrify

  @doc """
  Returns the list of uploads.

  ## Examples

      iex> list_uploads()
      [%Upload{}, ...]

  """
  def list_uploads do
    Repo.all(Upload)
  end

  @doc """
  Gets a single upload.

  Raises `Ecto.NoResultsError` if the Upload does not exist.

  ## Examples

      iex> get_upload!(123)
      %Upload{}

      iex> get_upload!(456)
      ** (Ecto.NoResultsError)

  """
  def get_upload!(id), do: Repo.get!(Upload, id)

  @doc """
  Creates a upload.

  ## Examples

      iex> create_upload(%{field: value})
      {:ok, %Upload{}}

      iex> create_upload(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_upload(attrs \\ %{}) do
    %Upload{}
    |> Upload.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a upload.

  ## Examples

      iex> update_upload(upload, %{field: new_value})
      {:ok, %Upload{}}

      iex> update_upload(upload, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_upload(%Upload{} = upload, attrs) do
    upload
    |> Upload.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Upload.

  ## Examples

      iex> delete_upload(upload)
      {:ok, %Upload{}}

      iex> delete_upload(upload)
      {:error, %Ecto.Changeset{}}

  """
  def delete_upload(%Upload{} = upload) do
    Repo.delete(upload)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking upload changes.

  ## Examples

      iex> change_upload(upload)
      %Ecto.Changeset{source: %Upload{}}

  """
  def change_upload(%Upload{} = upload) do
    Upload.changeset(upload, %{})
  end

  defp delete_header_image(%Upload{:filename => ""}) do
    :ok
  end

  defp delete_header_image(%Upload{} = upload) do
    case File.stat(Upload.local_path(upload.id, upload.filename)) do
      {:error, :enoent} ->
        :ok

      {:ok, _} ->
        File.rm!(Upload.local_path(upload.id, upload.filename))

        File.rm!(
          Upload.local_path(
            Integer.to_string(upload.id) <> "-timg",
            upload.filename
          )
        )
    end
  end

  def update_upload_from_plug_upload(
        post,
        %Plug.Upload{
          filename: filename,
          path: tmp_path,
          content_type: content_type
        }
      ) do
    hash =
      File.stream!(tmp_path, [], 2048)
      |> Upload.sha256()

    previous_hash = post.upload.hash

    case hash do
      ^previous_hash ->
        {:ok, post.upload}

      _ ->
        Repo.transaction(fn ->
          with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
               upload <- get_upload!(post.upload.id),
               {:ok, header_image} <-
                 upload
                 |> Ecto.Changeset.change(%{
                   filename: filename,
                   content_type: content_type,
                   size: size,
                   hash: hash
                 })
                 |> Repo.update(),
               :ok <-
                 File.cp(
                   tmp_path,
                   Upload.local_path(header_image.id, filename)
                 ),
               _header_image_thumbnail <-
                 open(Upload.local_path(header_image.id, filename))
                 |> resize("350x175")
                 |> save(
                   path:
                     Upload.local_path(Integer.to_string(header_image.id) <> "-timg", filename)
                 ),
               :ok <- delete_header_image(post.upload) do
            {:ok, header_image}
          else
            {:error, reason} -> Repo.rollback(reason)
          end
        end)
    end
  end

  def update_upload_from_plug_upload(
        post,
        nil
      ) do
    Repo.transaction(fn ->
      with upload <-
             get_upload!(post.upload.id),
           {:ok, header_image} <-
             upload
             |> Ecto.Changeset.change(%{
               filename: "",
               content_type: "",
               size: 0,
               hash: ""
             })
             |> Repo.update(),
           :ok <- delete_header_image(upload) do
        {:ok, header_image}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def create_upload_from_plug_upload(
        post,
        %Plug.Upload{
          filename: filename,
          path: tmp_path,
          content_type: content_type
        }
      ) do
    hash =
      File.stream!(tmp_path, [], 2048)
      |> Upload.sha256()

    Repo.transaction(fn ->
      with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
           header_image <-
             Ecto.build_assoc(post, :upload, %{
               filename: filename,
               content_type: content_type,
               hash: hash,
               size: size
             }),
           {:ok, header_image} <-
             header_image
             |> Repo.insert(),
           :ok <-
             File.cp(
               tmp_path,
               Upload.local_path(header_image.id, filename)
             ),
           _header_image_thumbnail <-
             open(Upload.local_path(header_image.id, filename))
             |> resize("350x175")
             |> save(
               path: Upload.local_path(Integer.to_string(header_image.id) <> "-timg", filename)
             ) do
        {:ok, header_image}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def create_upload_from_plug_upload(
        post,
        nil
      ) do
    Repo.transaction(fn ->
      with header_image <-
             Ecto.build_assoc(post, :upload, %{
               filename: "",
               content_type: "",
               hash: "",
               size: 0
             }),
           {:ok, header_image} <-
             header_image
             |> Repo.insert() do
        {:ok, header_image}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end
end
