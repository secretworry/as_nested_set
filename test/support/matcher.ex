defmodule AsNestedSet.Matcher do

  def match([source|source_tail], [target|target_tail]) do
    match(source, target) and match(source_tail, target_tail)
  end

  def match({source, source_children}, {target, target_children}) do
    match(source, target) and match(source_children, target_children)
  end

  def match([], []) do
    true
  end

  def match(source, target) when is_map(source) and is_map(target) do
    name = source.name
    lft = source.lft
    rgt = source.rgt
    taxonomy_id = source.taxonomy_id
    %{:name => ^name, :lft => ^lft, :rgt => ^rgt, :taxonomy_id => ^taxonomy_id} = target
    true
  end
end
