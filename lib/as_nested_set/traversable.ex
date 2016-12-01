defmodule AsNestedSet.Traversable do

  @type pre_fun :: (AsNestedSet.t, any -> {AsNestedSet.t, any})
  @type post_fun :: (AsNestedSet.t, [AsNestedSet.t], any -> {AsNestedSet.t, any}) | (AsNestedSet.t, any -> {AsNestedSet.t, any})

  @spec traverse(AsNestedSet.Scoped, any, pre_fun, post_fun) :: (Ecto.Repo.t -> {AsNestedSet.t, any})
  def traverse(%{__struct__: _} = node, context, pre, post) do
    fn repo ->
      node = do_reload(node, repo)
      {node, context} = call_pre(pre, node, context)
      do_traverse(node, context, pre, post, repo)
    end
  end

  @spec traverse(module, AsNestedSet.Scoped.scope, any, pre_fun, post_fun) :: (Ecto.Repo.t -> {[AsNestedSet.t], any})
  def traverse(module, scope, context, pre, post) do
    fn repo ->
      AsNestedSet.Queriable.roots(module, scope).(repo)
      |> do_traverse_children(context, pre, post, repo)
    end
  end

  defp do_traverse(node, context, pre, post, repo) do
    {children, context} = AsNestedSet.Queriable.children(node).(repo)
    |> do_traverse_children(context, pre, post, repo)
    call_post(post, do_reload(node, repo), do_reload(children, repo), context)
  end

  defp do_traverse_children([], context, _pre, _post, _repo), do: {[], context}
  defp do_traverse_children(children, context, pre, post, repo) do
    {children, context} = Enum.reduce(children, {[], context}, fn
      child, {acc, context} ->
        {child, context} = call_pre(pre, do_reload(child, repo), context)
        {child, context} = do_traverse(child, context, pre, post, repo)
        {[child|acc], context}
    end)
    {children |> Enum.reverse, context}
  end

  defp do_reload(nodes, repo) when is_list(nodes) do
    Enum.map(nodes, &do_reload(&1, repo))
  end

  defp do_reload(node, repo) do
    AsNestedSet.Modifiable.reload(node).(repo)
  end

  defp call_pre(pre, node, context) do
    pre.(node, context) |> check_callback_response(:pre)
  end

  defp call_post(post, node, children, context) when is_function(post, 3)do
    post.(node, children, context) |> check_callback_response(:post)
  end

  defp call_post(post, node, _children, context) when is_function(post, 2) do
    post.(node, context) |> check_callback_response(:post)
  end

  defp check_callback_response({_node, _context} = ok, _), do: ok
  defp check_callback_response(error, callback), do: raise ArgumentError, "Expect #{inspect callback} to return {AsNestedSet.t, context} but got #{inspect error}"
end