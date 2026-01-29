defmodule QuorumCodingChallenge.DatabaseTest do
  use QuorumCodingChallenge.DataCase
  alias QuorumCodingChallenge.Repo

  describe "database connection and basic queries" do
    test "can connect to database and count records" do
      # Count legislators
      {:ok, result} = Repo.query("SELECT COUNT(*) as count FROM legislators")
      assert is_list(result.rows)
      assert length(result.rows) >= 0

      # Count bills
      {:ok, result} = Repo.query("SELECT COUNT(*) as count FROM bills")
      assert is_list(result.rows)
      assert length(result.rows) >= 0

      # Count votes
      {:ok, result} = Repo.query("SELECT COUNT(*) as count FROM votes")
      assert is_list(result.rows)
      assert length(result.rows) >= 0

      # Count vote results
      {:ok, result} = Repo.query("SELECT COUNT(*) as count FROM vote_results")
      assert is_list(result.rows)
      assert length(result.rows) >= 0
    end

    test "can perform join queries" do
      {:ok, result} = Repo.query("""
      SELECT l.name, b.title, vr.vote_type
      FROM vote_results vr
      JOIN legislators l ON vr.legislator_id = l.id
      JOIN votes v ON vr.vote_id = v.id
      JOIN bills b ON v.bill_id = b.id
      LIMIT 3
      """)

      assert is_list(result.rows)
      # Verify structure of results if any data exists
      if length(result.rows) > 0 do
        [first_row | _] = result.rows
        assert length(first_row) == 3  # name, title, vote_type
      end
    end

    test "database tables have correct structure" do
      # Check legislators table structure
      {:ok, result} = Repo.query("PRAGMA table_info(legislators)")
      column_names = Enum.map(result.rows, fn row -> Enum.at(row, 1) end)
      assert "id" in column_names
      assert "name" in column_names

      # Check bills table structure
      {:ok, result} = Repo.query("PRAGMA table_info(bills)")
      column_names = Enum.map(result.rows, fn row -> Enum.at(row, 1) end)
      assert "id" in column_names
      assert "title" in column_names
      assert "sponsor_id" in column_names

      # Check votes table structure
      {:ok, result} = Repo.query("PRAGMA table_info(votes)")
      column_names = Enum.map(result.rows, fn row -> Enum.at(row, 1) end)
      assert "id" in column_names
      assert "bill_id" in column_names

      # Check vote_results table structure
      {:ok, result} = Repo.query("PRAGMA table_info(vote_results)")
      column_names = Enum.map(result.rows, fn row -> Enum.at(row, 1) end)
      assert "id" in column_names
      assert "legislator_id" in column_names
      assert "vote_id" in column_names
      assert "vote_type" in column_names
    end
  end
end
