defmodule QuorumCodingChallenge.SchemasTest do
  use ExUnit.Case, async: true

  alias QuorumCodingChallenge.Schemas.{Legislator, Bill, Vote, VoteResult}

  describe "schema compilation" do
    test "legislator schema compiles" do
      assert %Legislator{} = %Legislator{}
    end

    test "bill schema compiles" do
      assert %Bill{} = %Bill{}
    end

    test "vote schema compiles" do
      assert %Vote{} = %Vote{}
    end

    test "vote_result schema compiles" do
      assert %VoteResult{} = %VoteResult{}
    end
  end

  describe "changesets" do
    test "legislator changeset works" do
      changeset = Legislator.changeset(%Legislator{}, %{id: 1, name: "Test Legislator"})
      assert changeset.valid?
    end

    test "bill changeset works" do
      changeset = Bill.changeset(%Bill{}, %{id: 1, title: "Test Bill", sponsor_id: 1})
      assert changeset.valid?
    end

    test "vote changeset works" do
      changeset = Vote.changeset(%Vote{}, %{id: 1, bill_id: 1})
      assert changeset.valid?
    end

    test "vote_result changeset works" do
      changeset = VoteResult.changeset(%VoteResult{}, %{
        id: 1,
        legislator_id: 1,
        vote_id: 1,
        vote_type: 1
      })
      assert changeset.valid?
    end

    test "vote_result changeset validates vote_type" do
      # Valid vote types (1 = yea, 2 = nay)
      valid_changeset = VoteResult.changeset(%VoteResult{}, %{
        id: 1, legislator_id: 1, vote_id: 1, vote_type: 2
      })
      assert valid_changeset.valid?

      # Invalid vote type
      invalid_changeset = VoteResult.changeset(%VoteResult{}, %{
        id: 1, legislator_id: 1, vote_id: 1, vote_type: 3
      })
      refute invalid_changeset.valid?
      assert "must be 1 (yea) or 2 (nay)" in errors_on(invalid_changeset).vote_type
    end
  end

  describe "vote type utilities" do
    test "vote type constants" do
      assert VoteResult.vote_type_yea() == 1
      assert VoteResult.vote_type_nay() == 2
      assert VoteResult.valid_vote_types() == [1, 2]
    end

    test "vote type to string conversion" do
      assert VoteResult.vote_type_to_string(1) == "yea"
      assert VoteResult.vote_type_to_string(2) == "nay"
      assert VoteResult.vote_type_to_string(999) == "unknown"
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
