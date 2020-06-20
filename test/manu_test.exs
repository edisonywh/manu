defmodule Manu.FactoryTest do
  use ExUnit.Case

  alias Manu.{Address, User}

  test "builds should work" do
    defmodule Factory do
      use Manu.Factory

      def factory(User) do
        %User{
          name: "Hello World",
          email: "coconut@gmail.com"
        }
      end
    end

    assert %User{
             name: "Hello World",
             email: "coconut@gmail.com"
           } == Factory.build(User)
  after
    purge(Factory)
  end

  test "traits should work" do
    defmodule Factory do
      use Manu.Factory

      def factory(User) do
        %User{
          name: "Hello World",
          email: "coconut@gmail.com"
        }
      end

      def factory(User, :with_heymail) do
        %User{
          name: "Apple",
          email: "hello@hey.com"
        }
      end
    end

    assert %User{
             name: "Apple",
             email: "hello@hey.com"
           } == Factory.build(User, :with_heymail)
  after
    purge(Factory)
  end

  test "attrs should override default" do
    defmodule Factory do
      use Manu.Factory

      def factory(User) do
        %User{
          name: "Hello World",
          email: "coconut@gmail.com"
        }
      end
    end

    assert %User{
             name: "New Name",
             email: "coconut@gmail.com"
           } == Factory.build(User, :default, %{name: "New Name"})
  after
    purge(Factory)
  end

  describe "builds with changeset" do
    test "when using changeset/2 should work" do
      defmodule Factory do
        use Manu.Factory

        def factory(User) do
          %User{
            name: "Name",
            email: "invalid-email"
          }
        end
      end

      assert %User{
               name: "Name",
               email: "invalid-email"
             } == Factory.build(User)
    after
      purge(Factory)
    end

    test "when using email_changeset/2 should not work" do
      defmodule Factory do
        use Manu.Factory

        def factory(User) do
          %User{
            name: "Name",
            email: "invalid-email"
          }
        end
      end

      assert_raise Manu.Factory.InvalidChangesetError, fn ->
        Factory.build(User, :default, %{}, with: &User.email_changeset/2)
      end
    after
      purge(Factory)
    end

    test "when using email_changeset/2 but with valid override should work" do
      defmodule Factory do
        use Manu.Factory

        def factory(User) do
          %User{
            name: "Name",
            email: "invalid-email"
          }
        end
      end

      %User{name: "Name", email: "valid@email.com"} ==
        Factory.build(User, :default, %{email: "valid@email.com"}, with: &User.email_changeset/2)
    after
      purge(Factory)
    end
  end

  describe "assoc should work" do
    test "with changeset cast_assoc" do
      defmodule Factory do
        use Manu.Factory

        def factory(User) do
          %User{
            name: "Name",
            email: "valid@email.com",
            # Notice how we need to use `params_for` which returns a map. This is because `cast_assoc` work with raw maps.
            address: params_for(Address)
          }
        end

        def factory(Address) do
          %Address{
            lat: 12.0,
            lon: 15.0
          }
        end
      end

      assert %User{
               name: "Name",
               email: "valid@email.com",
               address: %Address{
                 lat: 12.0,
                 lon: 15.0
               }
             } == Factory.build(User, :default, %{}, with: &User.changeset_cast_assoc/2)
    after
      purge(Factory)
    end

    test "with changeset put_assoc" do
      defmodule Factory do
        use Manu.Factory

        def factory(User) do
          %User{
            name: "Name",
            email: "valid@email.com",
            # Notice how we need to use `build` which returns a struct. This is because `put_assoc` work with structs.
            address: build(Address)
          }
        end

        def factory(Address) do
          %Address{
            lat: 12.0,
            lon: 15.0
          }
        end
      end

      assert %User{
               name: "Name",
               email: "valid@email.com",
               address: %Address{
                 lat: 12.0,
                 lon: 15.0
               }
             } == Factory.build(User, :default, %{}, with: &User.changeset_put_assoc/2)
    after
      purge(Factory)
    end
  end

  test "trait with assoc" do
    defmodule Factory do
      use Manu.Factory

      def factory(User) do
        %User{
          name: "Name",
          email: "valid@email.com",
          address: params_for(Address)
        }
      end

      def factory(User, :with_bigger_lat_lon) do
        %User{
          name: "Bigger Lat Lon",
          email: "valid@email.com",
          address: Map.merge(params_for(Address), %{lat: 99.0, lon: 99.0})
        }
      end

      def factory(Address) do
        %Address{
          lat: 12.0,
          lon: 15.0
        }
      end
    end

    assert %User{
             name: "Bigger Lat Lon",
             email: "valid@email.com",
             address: %Address{
               lat: 99.0,
               lon: 99.0
             }
           } == Factory.build(User, :with_bigger_lat_lon, %{}, with: &User.changeset_cast_assoc/2)
  after
    purge(Factory)
  end

  test "when trait does not exists" do
    defmodule Factory do
      use Manu.Factory

      def factory(User) do
        %User{name: "none", email: "valid@gmail.com"}
      end
    end

    assert_raise Manu.Factory.UndefinedFactoryError, fn ->
      Factory.build(User, :non_existent)
    end
  after
    purge(Factory)
  end

  test "when schema does not exists" do
    defmodule Factory do
      use Manu.Factory
    end

    assert_raise Manu.Factory.UndefinedFactoryError, fn ->
      Factory.build(What)
    end
  after
    purge(Factory)
  end

  test "when default values are not valid changesets" do
    defmodule Factory do
      use Manu.Factory

      def factory(User) do
        %User{
          name: "s"
        }
      end
    end

    assert_raise Manu.Factory.InvalidChangesetError, fn ->
      Factory.build(User)
    end
  after
    purge(Factory)
  end

  test "apply list of traits" do
    defmodule Factory do
      use Manu.Factory

      def factory(User, :one) do
        %User{
          name: "one"
        }
      end

      def factory(User, :two) do
        %User{
          name: "two"
        }
      end

      def factory(User, :three) do
        %User{
          name: "three"
        }
      end
    end

    assert %User{
             name: "three",
           } == Factory.build(User, [:one, :two, :three])

    assert %User{
             name: "one",
           } == Factory.build(User, [:three, :two, :one])

    assert %User{
             name: "two",
           } == Factory.build(User, [:one, :three, :two])
  end

  defp purge(module) do
    :code.delete(module)
    :code.purge(module)
  end
end
