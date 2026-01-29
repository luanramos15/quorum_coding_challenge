defmodule QuorumCodingChallenge.VotingTest do
  use ExUnit.Case, async: true

  alias QuorumCodingChallenge.Voting

  describe "voting context" do
    test "module exists and is accessible" do
      # Ensure the module is compiled and loaded
      Code.ensure_loaded!(QuorumCodingChallenge.Voting)

      assert is_atom(Voting)
      assert function_exported?(Voting, :list_legislators, 0)
      assert function_exported?(Voting, :list_bills, 0)
      assert function_exported?(Voting, :list_votes, 0)
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
