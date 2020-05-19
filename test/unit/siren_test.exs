defmodule CopperTest.Siren do
  use ExUnit.Case
  import Dummy

  alias Copper.Siren
  alias Copper.Utils
  alias Plug.Conn

  test "merge_uris/2" do
    dummy URI, [{"merge/2", :merge}, {"to_string", :uri}] do
      assert Siren.merge_uris("lhs", "rhs") == :uri
      assert called(URI.merge("lhs", "rhs"))
      assert called(URI.to_string(:merge))
    end
  end

  test "change_page/2" do
    dummy Conn, [{"request_url", "url"}] do
      dummy URI, [{"encode_query", "query"}] do
        dummy Siren, [{"merge_uris/2", :merge}] do
          assert Siren.change_page(:conn, 2) == :merge
          assert called(Conn.request_url(:conn))
          assert called(URI.encode_query(%{"page" => 2}))
          assert called(Siren.merge_uris("url", "?query"))
        end
      end
    end
  end

  test "add_next/3" do
    expected = [%{"rel" => "next", "href" => :page}]

    dummy Utils, [{"get_page", 2}, {"get_items", 20}] do
      dummy Siren, [{"change_page/2", :page}] do
        assert Siren.add_next([], :conn, 100) == expected
        assert called(Utils.get_page(:conn))
        assert called(Utils.get_items(:conn))
        assert called(Siren.change_page(:conn, 3))
      end
    end
  end

  test "add_next/3 with items * page > count" do
    dummy Utils, [{"get_page", 1}, {"get_items", 200}] do
      assert Siren.add_next([], :conn, 100) == []
    end
  end

  test "add_next/3 on last page" do
    dummy Utils, [{"get_page", 5}, {"get_items", 20}] do
      assert Siren.add_next([], :conn, 100) == []
    end
  end

  test "add_last/3" do
    conn = %{query_params: %{}}
    expected = [%{"rel" => "last", "href" => :page}]

    dummy Utils, [{"get_items", 20}] do
      dummy Siren, [{"change_page/2", :page}] do
        assert Siren.add_last([], conn, 40) == expected
        assert called(Utils.get_items(conn))
        assert called(Siren.change_page(conn, 2))
      end
    end
  end

  test "add_prev/2" do
    conn = %{query_params: %{"page" => "2"}}

    dummy Siren, [{"change_page/2", :page}] do
      assert Siren.add_prev([], conn) == [%{"rel" => "prev", "href" => :page}]
      assert called(Siren.change_page(conn, 1))
    end
  end

  test "add_prev/2 on the first page" do
    assert Siren.add_prev([], %{query_params: %{"page" => "1"}}) == []
  end

  test "add_prev/2 without a page" do
    assert Siren.add_prev([], %{query_params: %{}}) == []
  end

  test "add_self/2" do
    dummy Conn, [{"request_url", :url}] do
      assert Siren.add_self([], :conn) == [%{"rel" => "self", "href" => :url}]
    end
  end

  test "links/2" do
    dummy Siren, [
      {"add_self/2", :self},
      {"add_prev/2", :prev},
      {"add_next/3", :next},
      {"add_last/3", :last}
    ] do
      assert Siren.links(:conn, :count) == :last
      assert Siren.add_self([], :conn)
      assert called(Siren.add_prev(:self, :conn))
      assert called(Siren.add_next(:prev, :conn, :count))
      assert called(Siren.add_last(:next, :conn, :count))
    end
  end

  test "encode/3" do
    expected = %{"entities" => :payload, "links" => :links}

    dummy Siren, [{"links/2", :links}] do
      assert Siren.encode(:conn, :payload, :count) == expected
      assert called(Siren.links(:conn, :count))
    end
  end

  test "encode/2" do
    expected = %{"properties" => :payload, "links" => [:self]}

    dummy Siren, [{"add_self/2", [:self]}] do
      assert Siren.encode(:conn, :payload) == expected
      assert called(Siren.add_self([], :conn))
    end
  end
end
