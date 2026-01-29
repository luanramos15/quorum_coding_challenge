defmodule QuorumCodingChallenge.SchemaTest do
  use QuorumCodingChallenge.DataCase
  alias QuorumCodingChallenge.Repo
  alias QuorumCodingChallenge.Schemas.{Legislator, Bill, Vote, VoteResult}

  describe "schema queries" do
    test "can query legislators using Ecto schemas" do
      legislators = Repo.all(Legislator)
      assert is_list(legislators)

      # If we have legislators, test their structure
      if length(legislators) > 0 do
        legislator = List.first(legislators)
        assert %Legislator{} = legislator
        assert is_integer(legislator.id)
        assert is_binary(legislator.name)
      end
    end

    test "can query bills using Ecto schemas" do
      bills = Repo.all(Bill)
      assert is_list(bills)

      # If we have bills, test their structure
      if length(bills) > 0 do
        bill = List.first(bills)
        assert %Bill{} = bill
        assert is_integer(bill.id)
        assert is_binary(bill.title)
        # sponsor_id can be nil or integer
        assert is_nil(bill.sponsor_id) or is_integer(bill.sponsor_id)
      end
    end

    test "can query votes using Ecto schemas" do
      votes = Repo.all(Vote)
      assert is_list(votes)

      # If we have votes, test their structure
      if length(votes) > 0 do
        vote = List.first(votes)
        assert %Vote{} = vote
        assert is_integer(vote.id)
        assert is_integer(vote.bill_id)
      end
    end

    test "can query vote results using Ecto schemas" do
      vote_results = Repo.all(VoteResult)
      assert is_list(vote_results)

      # If we have vote results, test their structure
      if length(vote_results) > 0 do
        vote_result = List.first(vote_results)
        assert %VoteResult{} = vote_result
        assert is_integer(vote_result.id)
        assert is_integer(vote_result.legislator_id)
        assert is_integer(vote_result.vote_id)
        assert is_integer(vote_result.vote_type)
        # Test vote type is valid (1 for yea, 2 for nay)
        assert vote_result.vote_type in [1, 2]
      end
    end

    test "can query with associations" do
      # Test querying bills with sponsors
      bills_with_sponsors = Repo.all(Bill) |> Repo.preload(:sponsor)
      assert is_list(bills_with_sponsors)

      # Test querying votes with bills
      votes_with_bills = Repo.all(Vote) |> Repo.preload(:bill)
      assert is_list(votes_with_bills)

      # Test querying vote results with associations
      vote_results_with_assocs = Repo.all(VoteResult) |> Repo.preload([:legislator, :vote])
      assert is_list(vote_results_with_assocs)
    end

    test "vote type constants work correctly" do
      assert VoteResult.vote_type_yea() == 1
      assert VoteResult.vote_type_nay() == 2
    end
  end

  describe "schema changesets and validation" do
    test "legislator changeset validates required fields" do
      changeset = Legislator.changeset(%Legislator{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).id

      changeset = Legislator.changeset(%Legislator{}, %{id: 1, name: "John Doe"})
      assert changeset.valid?
    end

    test "bill changeset validates required fields" do
      changeset = Bill.changeset(%Bill{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).id

      changeset = Bill.changeset(%Bill{}, %{id: 1, title: "Test Bill"})
      assert changeset.valid?
    end

    test "vote changeset validates required fields" do
      changeset = Vote.changeset(%Vote{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).bill_id
      assert "can't be blank" in errors_on(changeset).id

      changeset = Vote.changeset(%Vote{}, %{id: 1, bill_id: 1})
      assert changeset.valid?
    end

    test "vote result changeset validates required fields and vote type" do
      changeset = VoteResult.changeset(%VoteResult{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).legislator_id
      assert "can't be blank" in errors_on(changeset).vote_id
      assert "can't be blank" in errors_on(changeset).vote_type
      assert "can't be blank" in errors_on(changeset).id

      # Valid vote type
      changeset = VoteResult.changeset(%VoteResult{}, %{
        id: 1,
        legislator_id: 1,
        vote_id: 1,
        vote_type: 1
      })
      assert changeset.valid?

      # Invalid vote type
      changeset = VoteResult.changeset(%VoteResult{}, %{
        id: 1,
        legislator_id: 1,
        vote_id: 1,
        vote_type: 3
      })
      refute changeset.valid?
      # Use the actual error message from the schema
      vote_type_errors = errors_on(changeset).vote_type
      assert length(vote_type_errors) > 0
    end
  end
end
