defmodule UccChat.Application do

  def children do
    import Supervisor.Spec

    [
      # supervisor(UccChat.Presence, []),
      worker(UccChat.TypingAgent, []),
      worker(UccChat.MessageAgent, []),
      # worker(UccChat.UserAgent, []),
      worker(UccChat.PresenceAgent, []),
      # worker(UccChat.Robot.Adapters.UccChat, []),
      worker(UccChat.Robot, []),
      worker(UccChat.ChannelMonitor, [:chan_system]),
    ]
  end

  def start(_type, _args) do
    UccChatWeb.FlexBar.Defaults.add_buttons()
    UccChatWeb.RoomChannel.KeyStore.initialize()
  end

end
