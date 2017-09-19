defmodule ScpToAnywhere.SCP do
  @behaviour :ssh_daemon_channel
  alias ScpToAnywhere.Slack
  require Logger

  def init([]) do
    {:ok, %{}}
  end

  def handle_msg({:ssh_channel_up, chan_id, conn_man}, _state) do
    {:ok, %{:chan => chan_id, :conn => conn_man}}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:data, chan_id, 0, data}}, state=%{in_request: true, length: length}) when length > 0 do
    Logger.debug("Getting data #{byte_size(data)}")
    data_size = byte_size(data)
    rest_length = length - data_size

    if rest_length <= 0 do
      # Ugly hack to remove the zero byte at the end of the data
      fixed_data_size = data_size - 1
      << fixed_data :: binary-size(fixed_data_size), _leftover :: binary >> = data
      Slack.finish(state.ref, fixed_data)
      Logger.info("Done with transfer of #{state.file}")
      :ssh_connection.send(cm, chan_id, <<0>>)
      {:ok, %{state | in_request: false}}
    else
      Slack.send_part(state.ref, data)
      {:ok, %{state | length: rest_length}}
    end
  end

  def handle_ssh_msg({:ssh_cm, cm, {:data, chan_id, 0, data}}, state=%{in_request: true}) do
    Logger.info("Got data: #{inspect data}")
    <<command :: binary-size(1), _ :: binary>> = data
    case command do
      "C" ->
        [<<_ :: 8, mode :: binary>>, length|file] = String.split(data)
        file = file |> Enum.join(" ")
        length = String.to_integer(length)
        file = String.trim(file)
        Logger.info("Create file #{file}, length of #{length}, with mode #{mode}")
        ref = Slack.open_client()
        Slack.send_info(ref, Application.get_env(:scp_to_anywhere, :slack_token), state.dest, file)
        :ssh_connection.send(cm, chan_id, <<0>>)
        nstate =
          state
          |> Map.put(:length, length)
          |> Map.put(:og_length, length)
          |> Map.put(:file, file)
          |> Map.put(:data, <<>>)
          |> Map.put(:ref, ref)
        {:ok, nstate}
      _ ->
        Logger.info("Other command #{inspect command}")
        Logger.info("Data: #{inspect data}")
        :ssh_connection.close(cm, chan_id)
        {:ok, state}
    end
  end

  def handle_ssh_msg({:ssh_cm, cm, {:eof, chan_id}}, state) do
    Logger.debug("Got eof")
    :ssh_connection.send(cm, chan_id, <<0>>)
    :ssh_connection.close(cm, chan_id)
    {:ok, state}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:exec, chan_id, true, cmd}}, state) do
    user =
      :ssh.connection_info(cm, [:user])
      |> Keyword.get(:user)
      |> to_string()
    Logger.info("Got exec: #{cmd} from user: #{user}")
    command =
      cmd
      |> to_string()
      |> String.split()
    case command do
      ["scp"|rest] ->
        :ssh_connection.send(cm, chan_id, <<0>>)
        dest = rest |> List.last()
        nstate =
          state
          |> Map.put(:in_request, true)
          |> Map.put(:dest, dest)
          |> Map.put(:user, user)
        {:ok, nstate}
      _ ->
        :ssh_connection.send(cm, chan_id, "SCP ONLY\n")
        :ssh_connection.close(cm, chan_id)
        {:ok, state}
    end
  end

  def handle_ssh_msg(other, state) do
    Logger.info("Got unknown ssh msg: #{inspect other}")
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
