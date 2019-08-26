defmodule Blog.DocumentsTest do
  use Blog.DataCase

  alias Blog.Documents

  describe "uploads" do
    alias Blog.Documents.Upload

    @valid_attrs %{content_type: "some content_type", filename: "some filename", hash: "some hash", size: 42}
    @update_attrs %{content_type: "some updated content_type", filename: "some updated filename", hash: "some updated hash", size: 43}
    @invalid_attrs %{content_type: nil, filename: nil, hash: nil, size: nil}

    def upload_fixture(attrs \\ %{}) do
      {:ok, upload} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Documents.create_upload()

      upload
    end

    test "list_uploads/0 returns all uploads" do
      upload = upload_fixture()
      assert Documents.list_uploads() == [upload]
    end

    test "get_upload!/1 returns the upload with given id" do
      upload = upload_fixture()
      assert Documents.get_upload!(upload.id) == upload
    end

    test "create_upload/1 with valid data creates a upload" do
      assert {:ok, %Upload{} = upload} = Documents.create_upload(@valid_attrs)
      assert upload.content_type == "some content_type"
      assert upload.filename == "some filename"
      assert upload.hash == "some hash"
      assert upload.size == 42
    end

    test "create_upload/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Documents.create_upload(@invalid_attrs)
    end

    test "update_upload/2 with valid data updates the upload" do
      upload = upload_fixture()
      assert {:ok, %Upload{} = upload} = Documents.update_upload(upload, @update_attrs)
      assert upload.content_type == "some updated content_type"
      assert upload.filename == "some updated filename"
      assert upload.hash == "some updated hash"
      assert upload.size == 43
    end

    test "update_upload/2 with invalid data returns error changeset" do
      upload = upload_fixture()
      assert {:error, %Ecto.Changeset{}} = Documents.update_upload(upload, @invalid_attrs)
      assert upload == Documents.get_upload!(upload.id)
    end

    test "delete_upload/1 deletes the upload" do
      upload = upload_fixture()
      assert {:ok, %Upload{}} = Documents.delete_upload(upload)
      assert_raise Ecto.NoResultsError, fn -> Documents.get_upload!(upload.id) end
    end

    test "change_upload/1 returns a upload changeset" do
      upload = upload_fixture()
      assert %Ecto.Changeset{} = Documents.change_upload(upload)
    end
  end
end
