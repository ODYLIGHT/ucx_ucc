defmodule UccChat.Hooks do
  use Unbrella.Hooks, :add_hooks
  alias UcxUcc.Repo

  require Logger

  add_hook :preload_user, [:user, :preload] do
    Logger.debug "preload_user, preload: #{inspect preload}"
    Repo.preload user, preload
  end

  add_hook :register_admin_pages, UccChatWeb.Admin, :add_pages
end
