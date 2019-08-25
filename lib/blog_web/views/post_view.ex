defmodule BlogWeb.PostView do
  use BlogWeb, :view

  def format_date(date) do
    {:ok, date} = DateTime.from_naive(date, "Etc/UTC")

    Integer.to_string(date.day) <>
      "-" <> Integer.to_string(date.month) <> "-" <> Integer.to_string(date.year)
  end

  def display_brief(body) when byte_size(body) > 100 do
    body = String.slice(body, 0..100) <> "..."
  end

  def display_brief(body) do
    body
  end
end
