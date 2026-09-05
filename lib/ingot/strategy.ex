defmodule Ingot.Strategy do
  @moduledoc """
  Shared helpers for libcluster strategies.

  Strategies advertise `Node.self()` over Iroh or Zenoh and call
  `Cluster.Strategy.connect_nodes/4` when libcluster is loaded.
  """

  def topology(opts) do
    Keyword.get(opts, :topology, :ingot)
  end

  def config(opts) do
    Keyword.get(opts, :config, [])
  end

  def connect_fun(opts) do
    Keyword.get(opts, :connect, {:net_kernel, :connect_node, []})
  end

  def disconnect_fun(opts) do
    Keyword.get(opts, :disconnect, {:net_kernel, :disconnect_node, []})
  end

  def list_nodes_fun(opts) do
    Keyword.get(opts, :list_nodes, {:erlang, :nodes, [:connected]})
  end

  def interval(config, default \\ 5_000) do
    Keyword.get(config, :interval, default)
  end

  def node_name do
    Node.self()
  end

  def connect_nodes(topology, connect, list_nodes, nodes) when is_list(nodes) do
    if Code.ensure_loaded?(Cluster.Strategy) and
         function_exported?(Cluster.Strategy, :connect_nodes, 4) do
      Cluster.Strategy.connect_nodes(topology, connect, list_nodes, nodes)
    else
      Enum.each(nodes, fn n ->
        {m, f, a} = connect
        apply(m, f, a ++ [n])
      end)

      :ok
    end
  rescue
    _ -> :ok
  end

  def parse_nodes(payload) when is_binary(payload) do
    payload
    |> String.split([",", " ", "\n"], trim: true)
    |> Enum.map(&to_atom/1)
    |> Enum.reject(&is_nil/1)
  end

  def parse_nodes(_), do: []

  defp to_atom(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> String.to_atom(str)
  end
end
