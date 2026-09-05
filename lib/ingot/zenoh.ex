defmodule Ingot.Zenoh do
  @moduledoc """
  Brokered Zenoh client. Talks to **zenohd**, not peer-mesh.

  Requires optional `{:zenohex, "~> 0.10"}`.
  """
  use GenServer
  require Logger

  def available?, do: Code.ensure_loaded?(Zenohex.Session)

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def put(key, payload), do: GenServer.call(__MODULE__, {:put, key, payload})
  def session, do: GenServer.call(__MODULE__, :session)

  @impl true
  def init(opts) do
    connect = Keyword.get(opts, :connect, "tcp/127.0.0.1:7447")
    key = Keyword.get(opts, :key, "ingot/cluster/**")
    mode = Keyword.get(opts, :mode, :client)
    live = Keyword.get(opts, :live, true)

    if available?() and live do
      case open_session(connect, mode) do
        {:ok, session} ->
          _ = maybe_sub(session, key)
          Logger.info("Ingot.Zenoh client → #{connect} key=#{key}")
          {:ok, %{session: session, connect: connect, key: key}}

        {:error, reason} ->
          {:stop, reason}
      end
    else
      Logger.warning("Ingot.Zenoh stub (zenohex=#{available?()} live=#{live} connect=#{connect})")
      {:ok, %{session: nil, connect: connect, key: key, stub: true}}
    end
  end

  @impl true
  def handle_call(:session, _from, state), do: {:reply, {:ok, state.session}, state}

  def handle_call({:put, _key, _payload}, _from, %{stub: true} = state) do
    {:reply, {:error, :backend_not_loaded}, state}
  end

  def handle_call({:put, key, payload}, _from, %{session: session} = state) do
    result = put_sample(session, key, payload)
    {:reply, result, state}
  end

  defp open_session(connect, _mode) do
    # Zenohex 0.10: Session.open/1 takes config map when present.
    cond do
      function_exported?(Zenohex.Session, :open, 1) ->
        Zenohex.Session.open(%{connect: [connect], mode: "client"})

      function_exported?(Zenohex.Session, :open, 0) ->
        Zenohex.Session.open()

      true ->
        {:error, :no_session_api}
    end
  rescue
    e -> {:error, e}
  end

  defp maybe_sub(session, key) do
    if function_exported?(Zenohex.Session, :declare_subscriber, 2) do
      Zenohex.Session.declare_subscriber(session, key)
    else
      :ok
    end
  rescue
    _ -> :ok
  end

  defp put_sample(session, key, payload) do
    cond do
      function_exported?(Zenohex.Session, :declare_publisher, 2) ->
        with {:ok, pub} <- Zenohex.Session.declare_publisher(session, key) do
          if function_exported?(Zenohex.Publisher, :put, 2) do
            Zenohex.Publisher.put(pub, payload)
          else
            {:error, :no_publisher_put}
          end
        end

      true ->
        {:error, :no_publisher_api}
    end
  rescue
    e -> {:error, e}
  end
end
