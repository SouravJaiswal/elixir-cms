defmodule Blog.Repo.Migrations.AddHeaderImageToPost do
  use Ecto.Migration

  def change do
    alter table(:uploads) do
      add(:post_id, references(:posts))
    end
  end
end
