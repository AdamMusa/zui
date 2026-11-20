# frozen_string_literal: true

require "json"

# A Ruby model of the native client's node index, written from the rules in
# Service.qml (validateNode, applyPatch, validSetPatch, commitNodeIndex).
#
# It exists so a test can feed it the exact message stream an Application
# emitted and ask what the client would have done with it. The client refuses
# a bad message whole and says nothing to Ruby, so every refusal it would have
# made is recorded in #refusals; a correct stream leaves that empty.
class ClientModel
  MAX_NODES = 2000
  MAX_NODE_DEPTH = 32
  MAX_VALUE_DEPTH = 8
  MAX_ITEMS = 256
  MAX_STRING = 16_384
  MAX_BATCH = 256

  attr_reader :index, :refusals, :roots

  def initialize
    @index = {}
    @roots = {}
    @refusals = []
  end

  def feed(raw)
    raw.each_line { |line| apply(JSON.parse(line)) }
    self
  end

  def apply(message)
    case message["type"]
    when "render" then render(message)
    when "patch" then patch(message)
    end
  end

  # The tree the client would currently draw, in the same shape as
  # Application#tree, rebuilt from the index so a stale entry shows up.
  def tree
    @roots.transform_values { |root| materialize(root) }
  end

  def live?(id) = @index.key?(id)

  private

  def render(message)
    index = {}
    message.fetch("surfaces").each_value do |root|
      reason = register(root, index, 0, { count: 0 })
      return refuse("render: #{reason}") if reason
    end
    @index = index
    @roots = message.fetch("surfaces").transform_values { |root| root["id"] }
  end

  def patch(message)
    case message["op"]
    when "batch" then batch(message)
    when "set" then set_one(message)
    when "replace_children" then replace_children(message)
    when "animate" then nil
    end
  end

  def batch(message)
    patches = message["patches"]
    return refuse("batch size #{patches&.length}") if !patches.is_a?(Array) || patches.empty? || patches.length > MAX_BATCH

    patches.each do |entry|
      reason = set_problem(entry)
      return refuse("batch rejected: #{reason}") if reason
    end
    patches.each { |entry| write(entry) }
  end

  def set_one(message)
    reason = set_problem(message)
    return refuse("set rejected: #{reason}") if reason

    write(message)
  end

  def set_problem(entry)
    node = @index[entry["id"]]
    return "no live node #{entry['id']}" unless node
    return "value of #{entry['id']}.#{entry['property']} out of bounds" unless bounded?(entry["value"], 0)

    nil
  end

  def write(entry)
    node = @index.fetch(entry["id"])
    node["props"] = (node["props"] || {}).merge(entry["property"] => entry["value"])
  end

  def replace_children(message)
    node = @index[message["id"]]
    return refuse("replace target #{message['id']} is not live") unless node

    removed = {}
    mark = lambda do |child|
      return if removed.key?(child["id"])

      removed[child["id"]] = true
      live = @index[child["id"]]
      (live ? live["children"] : child["children"]).to_a.each { |nested| mark.call(nested) }
    end
    node["children"].to_a.each { |child| mark.call(child) }

    index = @index.reject { |id, _| removed.key?(id) || id == node["id"] }
    count = { count: index.length }
    message["children"].each do |child|
      reason = register(child, index, 0, count)
      return refuse("replace #{message['id']} rejected: #{reason}") if reason
    end
    node["children"] = message["children"]
    index[node["id"]] = node
    @index = index
  end

  def register(node, index, depth, count)
    return "node nested deeper than #{MAX_NODE_DEPTH}" if depth > MAX_NODE_DEPTH
    return "more than #{MAX_NODES} live nodes" if count[:count] >= MAX_NODES
    return "id #{node['id']} already live" if index.key?(node["id"])

    (node["props"] || {}).each do |key, value|
      return "property #{node['id']}.#{key} is out of bounds" unless bounded?(value, 0)
    end
    index[node["id"]] = node
    count[:count] += 1
    node["children"].to_a.each do |child|
      reason = register(child, index, depth + 1, count)
      return reason if reason
    end
    nil
  end

  def bounded?(value, depth)
    return false if depth > MAX_VALUE_DEPTH

    case value
    when nil, true, false, Numeric then true
    when String then value.length <= MAX_STRING
    when Array then value.length <= MAX_ITEMS && value.all? { |item| bounded?(item, depth + 1) }
    when Hash
      value.length <= MAX_ITEMS && value.all? { |key, item| key.length <= 128 && bounded?(item, depth + 1) }
    else false
    end
  end

  def materialize(id)
    node = @index.fetch(id)
    result = { "type" => node["type"], "id" => node["id"] }
    result["props"] = node["props"] if node["props"] && !node["props"].empty?
    children = node["children"].to_a
    result["children"] = children.map { |child| materialize(child["id"]) } unless children.empty?
    result["events"] = node["events"] if node["events"] && !node["events"].empty?
    result
  end

  def refuse(reason)
    @refusals << reason
    nil
  end
end
