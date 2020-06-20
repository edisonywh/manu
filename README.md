# Manu

## WARNING 🚨: Manu is a proof-of-concept to see how it would look like to use changesets with our test factories.

Manu allow you to create your test data and associations with custom changesets.

# Why Manu?

ExMachina is the popular alternative, but it does not come with good changeset support, and that is what Manu is trying to solve.

Disclaimer: I am not a heavy user of ExMachina so perhaps there are ways/patterns to make it work, I just find it peculiar that people seem to dislike it and I'd like to understand why and maybe start a conversation around it.

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
- Take `cast_assoc` and `put_assoc` for example, `cast` expects a map and `put` expects a struct, Manu follows the same way, so you need to be mindful about using `build` vs `params_for`.

# Example
For examples, look over in `manu_tests.exs`
