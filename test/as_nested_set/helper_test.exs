defmodule AsNestedSet.HelperTest do

  use AsNestedSet.EctoCase
  
  import AsNestedSet.Helper

  defmodule Sample do
    use AsNestedSet
    defstruct id: "id", lft: "left", rgt: "right", parent_id: "parent_id"
  end
  
  describe "fields/1" do
    
    test "should return fields configurations for specified module" do
      assert %{left: :lft, node_id: :id, parent_id: :parent_id, right: :rgt} = fields(Sample)
    end
  end

end
