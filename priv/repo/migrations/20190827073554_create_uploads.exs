defmodule Blog.Repo.Migrations.CreateUploads do
  use Ecto.Migration

  def change do
    create table(:uploads) do
      add(:content_type, :string)
      add(:filename, :string)
      add(:hash, :string, size: 64)
      add(:size, :bigint)

      add(:post_id, references(:posts))

      timestamps()
    end
  end
end
