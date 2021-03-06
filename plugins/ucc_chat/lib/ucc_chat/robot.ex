Code.ensure_compiled UccChat.Robot.Adapters.UccChat
defmodule UccChat.Robot do
  use Hedwig.Robot, otp_app: :ucx_ucc
  require Logger

  def handle_connect(%{name: name} = state) do
    if :undefined == :global.whereis_name(name) do
      :yes = :global.register_name(name, self())
    end
    # Logger.warn "name: " <> inspect(name)


    {:ok, state}
  end

  def handle_disconnect(_reason, state) do
    {:reconnect, 5000, state}
  end

  def handle_in(%Hedwig.Message{} = msg, state) do
    {:dispatch, msg, state}
  end

  def handle_in(_msg, state) do
    {:noreply, state}
  end
end
