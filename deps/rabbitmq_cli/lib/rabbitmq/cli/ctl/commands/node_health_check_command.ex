## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.

defmodule RabbitMQ.CLI.Ctl.Commands.NodeHealthCheckCommand do
  @behaviour RabbitMQ.CLI.CommandBehaviour

  defp default_opts() do
    %{timeout: 70000}
  end

  def scopes(), do: [:ctl, :diagnostic]

  def validate(args, _) when length(args) > 0, do: {:validation_failure, :too_many_args}
  def validate([], _), do: :ok

  def merge_defaults(args, opts) do
    {args, Map.merge(default_opts, opts)}
  end

  def flags() do
    [:timeout]
  end

  def switches(), do: [timeout: :integer]

  def aliases(), do: []

  def usage, do: "node_health_check"

  def banner(_, %{node: node_name}), do: "Checking health of node #{node_name} ..."

  def run([], %{node: node_name, timeout: timeout}) do
    case :rabbit_misc.rpc_call(node_name, :rabbit_health_check, :node, [node_name, timeout]) do
      :ok                                      ->
        :ok
      true                                     ->
        :ok
      {:badrpc, _} = err                       ->
        err
      {:error_string, error_message}           ->
        {:healthcheck_failed, error_message}
      {:node_is_ko, error_message, _exit_code} ->
        {:healthcheck_failed, error_message}
      other                                    ->
        other
    end
  end

  def output({:healthcheck_failed, message}, _) do
    {:error, RabbitMQ.CLI.ExitCodes.exit_software,
     "Error: healthcheck failed. Message: #{message}"}
  end
  use RabbitMQ.CLI.DefaultOutput
end
