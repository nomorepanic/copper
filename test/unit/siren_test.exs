defmodule CopperTest.Siren do
  use ExUnit.Case
  import Dummy

  alias Copper.Siren
  alias Copper.Utils
  alias Plug.Conn

  test "parse_uri/1" do
    dummy Conn, [{"request_url", :url}] do
      dummy URI, [{"parse", :parsed}] do
        assert Siren.parse_uri(:conn) == :parsed
        assert called(Conn.request_url(:conn))
        assert called(URI.parse(:url))
      end
    end
  end

  test "decode_query/1" do
    dummy URI, [{"decode_query", :query}] do
      assert Siren.decode_query(%{query: "x=value"}) == :query
      assert called(URI.decode_query("x=value"))
    end
  end

  test "decode_query/1 when the url has none" do
    assert Siren.decode_query(%{query: nil}) == %{}
  end

  test "link/2" do
    assert Siren.link("type", "href") == %{rel: ["type"], href: "href"}
  end

  test "change_page/2" do
    url = %{query: "page=1"}

    dummy URI, [{"encode_query", "query"}, {"to_string", :string}] do
      dummy Siren, [{"parse_uri", url}, {"decode_query", %{}}] do
        assert Siren.change_page(:conn, 2) == :string
        assert called(Siren.parse_uri(:conn))
        assert called(Siren.decode_query(url))
        assert called(URI.encode_query(%{"page" => 2}))
        assert called(URI.to_string(%{query: "query"}))
      end
    end
  end

  test "add_next/3" do
    dummy Utils, [{"get_page", 2}, {"get_items", 20}] do
      dummy Siren, [{"change_page/2", :page}, {"link/2", :link}] do
        assert Siren.add_next([], :conn, 100) == [:link]
        assert called(Utils.get_page(:conn))
        assert called(Utils.get_items(:conn))
        assert called(Siren.change_page(:conn, 3))
        assert called(Siren.link("next", :page))
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

    dummy Utils, [{"get_items", 20}] do
      dummy Siren, [{"change_page/2", :page}, {"link/2", :link}] do
        assert Siren.add_last([], conn, 40) == [:link]
        assert called(Utils.get_items(conn))
        assert called(Siren.change_page(conn, 2))
        assert called(Siren.link("last", :page))
      end
    end
  end

  test "add_prev/2" do
    conn = %{query_params: %{"page" => "2"}}

    dummy Siren, [{"change_page/2", :page}, {"link/2", :link}] do
      assert Siren.add_prev([], conn) == [:link]
      assert called(Siren.change_page(conn, 1))
      assert called(Siren.link("prev", :page))
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
      dummy Siren, [{"link/2", :link}] do
        assert Siren.add_self([], :conn) == [:link]
        assert called(Siren.link("self", :url))
      end
    end
  end

  test "add_first/2" do
    dummy Siren, [{"change_page/2", :page}, {"link/2", :link}] do
      assert Siren.add_first([], :conn) == [:link]
      assert called(Siren.change_page(:conn, 1))
      assert called(Siren.link("first", :page))
    end
  end

  test "links/2" do
    dummy Siren, [
      {"add_self/2", :self},
      {"add_prev/2", :prev},
      {"add_first/2", :first},
      {"add_next/3", :next},
      {"add_last/3", :last}
    ] do
      assert Siren.links(:conn, :count) == :last
      assert Siren.add_self([], :conn)
      assert called(Siren.add_prev(:self, :conn))
      assert called(Siren.add_first(:prev, :conn))
      assert called(Siren.add_next(:first, :conn, :count))
      assert called(Siren.add_last(:next, :conn, :count))
    end
  end

  test "encode/3" do
    expected = %{entities: :payload, links: :links}

    dummy Siren, [{"links/2", :links}] do
      assert Siren.encode(:conn, :payload, :count) == expected
      assert called(Siren.links(:conn, :count))
    end
  end

  test "encode/2" do
    expected = %{properties: :payload, links: [:self]}

    dummy Siren, [{"add_self/2", [:self]}] do
      assert Siren.encode(:conn, :payload) == expected
      assert called(Siren.add_self([], :conn))
    end
  end
end
