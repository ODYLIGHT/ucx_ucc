defmodule UccChatWeb.Admin.Page.PhoneNumbers do
  use UccAdmin.Page

  # import Ecto.Query
  import UcxUccWeb.Gettext

  # alias UcxUcc.Repo
  alias UcxUcc.Accounts

  require Logger

  def add_page do
    new("admin_phone_numbers", __MODULE__, ~g(Phone Numbers), UccChatWeb.AdminView, "phone_numbers.html", 41)
  end

  def args(page, user, _sender, socket) do
    labels = Accounts.list_phone_number_labels()

    {[
      labels: labels
    ], user, page, socket}
  end
end
