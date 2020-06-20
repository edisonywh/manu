defmodule Manu.Factory do
  @moduledoc """
  ## WARNING 🚨: #{__MODULE__} is a proof-of-concept to see how it would \
    look like to use changesets with our test factories.

  Manu allow you to create your test data and associations
  with custom changesets.

  # Why Manu?

  ExMachina is the popular alternative, but it does not come with good changeset support,
  and that is what Manu is trying to solve.

  Disclaimer: I am not a heavy user of ExMachina so perhaps there are ways/patterns to
  make it work, I just find it peculiar that people seem to dislike it and I'd like to
  understand why and maybe start a conversation around it.

  For reference: https://github.com/thoughtbot/ex_machina/pull/78

  # What does Manu do different from ExMachina?
    - Everything is validated with changesets.
    - Encourages use of changesets, which is good to do.
    - Allows you to specify a changeset to be used while building a struct.

  # Cons
  - Usage can potentially get ugly, for example, the calls can look like so:
    - build(User)
    - build(User, :default)
    - build(User, :with_gmail)
    - build(User, :default, %{name: "new_name"})
    - build(User, :default, %{}, with: &User.email_changeset/2)

  # Caveat
  - Take `cast_assoc` and `put_assoc` for example, `cast` expects a map and `put` \
    expects a struct, Manu follows the same way, so you need to be mindful about \
    using `build` vs `params_for`.

  # Example
  For examples, look over in `manu_tests.exs`
  """

  defmodule InvalidChangesetError do
    defexception [:message]
  end

  defmodule UndefinedFactoryError do
    defexception [:message]
  end

  def build(factory, schema, traits, attrs, opts) do
    changeset = Keyword.get(opts, :with, &schema.changeset/2)

    result =
      case traits do
        :default ->
          apply(factory, :factory, [schema])

        trait when is_atom(trait) ->
          apply(factory, :factory, [schema, trait])

        traits when is_list(traits) ->
          Enum.reduce(traits, %{}, fn trait, acc ->
            acc
            |> Map.merge(apply(factory, :factory, [schema, trait]))
          end)
      end

    result
    |> Map.merge(attrs)
    |> Manu.Factory.validate!(changeset)
  end

  defmacro __using__(_opts) do
    quote do
      import Manu.Factory
      @before_compile Manu.Factory

      def build(schema, trait \\ :default, attrs \\ %{}, opts \\ []) do
        Manu.Factory.build(__MODULE__, schema, trait, attrs, opts)
      end

      def params_for(schema, trait \\ :default),
        do:
          build(schema, trait)
          |> Map.from_struct()
          |> Map.drop([:__meta__])
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def factory(schema, trait \\ :default),
        do:
          raise(
            UndefinedFactoryError,
            "Factory is not defined for #{schema} with trait :#{trait}"
          )
    end
  end

  def validate!(schema, changeset) do
    attrs = Map.from_struct(schema)

    schema.__struct__()
    |> struct!()
    |> changeset.(attrs)
    |> do_validate!()
  end

  defp do_validate!(%Ecto.Changeset{data: _data, valid?: true} = changeset) do
    changeset
    |> Ecto.Changeset.apply_changes()
  end

  defp do_validate!(%Ecto.Changeset{valid?: false} = changeset) do
    error =
      changeset
      |> make_error()

    struct = changeset.data.__struct__

    # TODO: Need to improve the message here.
    # Ideas:
    # - make sure stacktrace has the exact location of this.
    # - maybe show the actual value that failed the validations.
    raise InvalidChangesetError,
      message: "Error while building #{struct} because #{inspect(error)}"
  end

  defp make_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
