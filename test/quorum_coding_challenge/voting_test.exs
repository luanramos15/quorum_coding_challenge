defmodule QuorumCodingChallenge.VotingTest do
  use QuorumCodingChallenge.DataCase

  alias QuorumCodingChallenge.Voting
  alias QuorumCodingChallenge.Schemas.{Legislator, Bill, Vote, VoteResult}

  setup do
    # Create test data
    legislator1 = %Legislator{id: 1, name: "John Doe"} |> Repo.insert!()
    legislator2 = %Legislator{id: 2, name: "Jane Smith"} |> Repo.insert!()

    bill1 = %Bill{id: 101, title: "Test Bill 1", sponsor_id: 1} |> Repo.insert!()
    bill2 = %Bill{id: 102, title: "Test Bill 2", sponsor_id: 2} |> Repo.insert!()

    vote1 = %Vote{id: 201, bill_id: 101} |> Repo.insert!()
    vote2 = %Vote{id: 202, bill_id: 102} |> Repo.insert!()

    vote_result1 = %VoteResult{id: 301, legislator_id: 1, vote_id: 201, vote_type: 1} |> Repo.insert!()
    vote_result2 = %VoteResult{id: 302, legislator_id: 2, vote_id: 201, vote_type: 2} |> Repo.insert!()
    vote_result3 = %VoteResult{id: 303, legislator_id: 1, vote_id: 202, vote_type: 2} |> Repo.insert!()
    vote_result4 = %VoteResult{id: 304, legislator_id: 2, vote_id: 202, vote_type: 1} |> Repo.insert!()

    %{
      legislators: [legislator1, legislator2],
      bills: [bill1, bill2],
      votes: [vote1, vote2],
      vote_results: [vote_result1, vote_result2, vote_result3, vote_result4]
    }
  end

  describe "list functions" do
    test "list_legislators/0 returns all legislators", %{legislators: _legislators} do
      result = Voting.list_legislators()
      assert length(result) >= 2
      assert Enum.any?(result, &(&1.name == "John Doe"))
      assert Enum.any?(result, &(&1.name == "Jane Smith"))
    end

    test "list_bills/0 returns all bills", %{bills: _bills} do
      result = Voting.list_bills()
      assert length(result) >= 2
      assert Enum.any?(result, &(&1.title == "Test Bill 1"))
      assert Enum.any?(result, &(&1.title == "Test Bill 2"))
    end

    test "list_votes/0 returns all votes", %{votes: _votes} do
      result = Voting.list_votes()
      assert length(result) >= 2
      assert Enum.any?(result, &(&1.id == 201))
      assert Enum.any?(result, &(&1.id == 202))
    end
  end

  describe "get functions" do
    test "get_legislator!/1 returns legislator by id", %{legislators: [legislator1, _]} do
      result = Voting.get_legislator!(legislator1.id)
      assert result.id == legislator1.id
      assert result.name == "John Doe"
    end

    test "get_legislator!/1 raises when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Voting.get_legislator!(99999)
      end
    end

    test "get_bill!/1 returns bill by id", %{bills: [bill1, _]} do
      result = Voting.get_bill!(bill1.id)
      assert result.id == bill1.id
      assert result.title == "Test Bill 1"
    end

    test "get_bill!/1 raises when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Voting.get_bill!(99999)
      end
    end

    test "get_vote!/1 returns vote by id", %{votes: [vote1, _]} do
      result = Voting.get_vote!(vote1.id)
      assert result.id == vote1.id
      assert result.bill_id == 101
    end

    test "get_vote!/1 raises when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Voting.get_vote!(99999)
      end
    end
  end

  describe "vote analysis functions" do
    test "get_vote_results_for_vote/1 returns vote results for a specific vote" do
      vote_results = Voting.get_vote_results_for_vote(201)
      assert length(vote_results) == 2

      yea_vote = Enum.find(vote_results, &(&1.vote_type == 1))
      assert yea_vote.legislator_name == "John Doe"

      nay_vote = Enum.find(vote_results, &(&1.vote_type == 2))
      assert nay_vote.legislator_name == "Jane Smith"
    end

    test "get_legislator_votes/1 returns all votes for a legislator" do
      votes = Voting.get_legislator_votes(1)
      assert length(votes) == 2

      # Check that we have the right vote types
      vote_types = Enum.map(votes, & &1.vote_type)
      assert 1 in vote_types  # Yea vote
      assert 2 in vote_types  # Nay vote
    end

    test "get_votes_by_type/2 returns yea votes for a bill" do
      yea_votes = Voting.get_votes_by_type(101, 1)  # bill_id, vote_type
      assert length(yea_votes) == 1
      assert hd(yea_votes).vote_type == 1
    end

    test "get_votes_by_type/2 returns nay votes for a bill" do
      nay_votes = Voting.get_votes_by_type(101, 2)  # bill_id, vote_type
      assert length(nay_votes) == 1
      assert hd(nay_votes).vote_type == 2
    end

    test "get_opposing_votes/1 returns votes on both sides of a bill" do
      opposing_votes = Voting.get_opposing_votes(101)
      assert length(opposing_votes) == 2  # Both yea and nay votes

      vote_types = Enum.map(opposing_votes, & &1.vote_type)
      assert 1 in vote_types
      assert 2 in vote_types
    end

    test "get_votes_by_type/2 returns votes filtered by type" do
      yea_votes = Voting.get_votes_by_type(101, 1)  # bill_id, vote_type
      nay_votes = Voting.get_votes_by_type(101, 2)  # bill_id, vote_type

      assert length(yea_votes) == 1
      assert length(nay_votes) == 1
      assert hd(yea_votes).vote_type == 1
      assert hd(nay_votes).vote_type == 2
    end

    test "get_bill_vote_summary_with_labels/1 returns labeled vote summary" do
      summary = Voting.get_bill_vote_summary_with_labels(101)
      assert length(summary) == 2

      # Find yea and nay votes
      yea_summary = Enum.find(summary, fn s -> s.vote_label == "yea" end)
      nay_summary = Enum.find(summary, fn s -> s.vote_label == "nay" end)

      assert yea_summary.count == 1
      assert nay_summary.count == 1
    end
  end

  describe "edge cases" do
    test "functions handle non-existent IDs gracefully" do
      assert Voting.get_vote_results_for_vote(99999) == []
      assert Voting.get_bill_vote_summary(99999) == []
      assert Voting.get_legislator_votes(99999) == []
    end

    test "vote summary handles bills with no votes" do
      _bill3 = %Bill{id: 103, title: "No Votes Bill"} |> Repo.insert!()
      summary = Voting.get_bill_vote_summary(103)
      assert summary == []
    end
  end

  describe "module info" do
    test "module exists and is accessible" do
      Code.ensure_loaded!(QuorumCodingChallenge.Voting)
      assert is_atom(Voting)
    end

    test "context has expected public functions" do
      functions = Voting.__info__(:functions)

      expected_functions = [
        {:list_legislators, 0},
        {:list_bills, 0},
        {:list_votes, 0},
        {:get_legislator!, 1},
        {:get_bill!, 1},
        {:get_vote!, 1},
        {:get_vote_results_for_vote, 1},
        {:get_bill_vote_summary, 1},
        {:get_legislator_votes, 1},
        {:get_opposing_votes, 1},
        {:get_yea_votes, 1},
        {:get_nay_votes, 1},
        {:get_votes_by_type, 2},
        {:get_bill_vote_summary_with_labels, 1}
      ]

      for {fun, arity} <- expected_functions do
        assert {fun, arity} in functions, "Expected function #{fun}/#{arity} not found"
      end
    end
  end
end
