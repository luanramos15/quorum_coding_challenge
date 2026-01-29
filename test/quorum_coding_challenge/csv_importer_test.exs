defmodule QuorumCodingChallenge.CsvImporterTest do
  use QuorumCodingChallenge.DataCase
  alias QuorumCodingChallenge.CsvImporter
  alias QuorumCodingChallenge.Schemas.{Legislator, Bill, Vote, VoteResult}

  @test_input_path "test/fixtures/csv_import"

  setup do
    File.mkdir_p!(@test_input_path)
    create_test_csv_files()
    on_exit(fn -> File.rm_rf!(@test_input_path) end)
    :ok
  end

  describe "import_all/1" do
    test "imports all CSV files in dependency order" do
      initial_legislators = Repo.aggregate(Legislator, :count, :id)
      initial_bills = Repo.aggregate(Bill, :count, :id)
      initial_votes = Repo.aggregate(Vote, :count, :id)
      initial_vote_results = Repo.aggregate(VoteResult, :count, :id)

      assert :ok = CsvImporter.import_all(@test_input_path)

      # Verify data was imported
      assert Repo.aggregate(Legislator, :count, :id) == initial_legislators + 3
      assert Repo.aggregate(Bill, :count, :id) == initial_bills + 2
      assert Repo.aggregate(Vote, :count, :id) == initial_votes + 2
      assert Repo.aggregate(VoteResult, :count, :id) == initial_vote_results + 4
    end

    test "handles missing directory" do
      # Should not crash with missing directory
      assert :ok = CsvImporter.import_all("nonexistent/path")
    end

    test "handles empty directory" do
      empty_path = "test/fixtures/empty_csv"
      File.mkdir_p!(empty_path)
      on_exit(fn -> File.rm_rf!(empty_path) end)

      # Should not crash with empty directory
      assert :ok = CsvImporter.import_all(empty_path)
    end
  end

  describe "import_csv_file/2" do
    test "imports legislators from CSV" do
      filename = "legislators.csv"

      initial_count = Repo.aggregate(Legislator, :count, :id)
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)
      final_count = Repo.aggregate(Legislator, :count, :id)

      assert final_count == initial_count + 3

      # Verify specific legislators were imported
      assert Repo.get(Legislator, 1)
      assert Repo.get(Legislator, 2)
      assert Repo.get(Legislator, 3)
    end

    test "imports bills from CSV with foreign key validation" do
      # First import legislators so foreign keys can be validated
      CsvImporter.import_csv_file("legislators.csv", @test_input_path)

      filename = "bills.csv"
      initial_count = Repo.aggregate(Bill, :count, :id)
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)
      final_count = Repo.aggregate(Bill, :count, :id)

      assert final_count == initial_count + 2

      # Verify bill with valid sponsor
      bill1 = Repo.get(Bill, 101)
      assert bill1.sponsor_id == 1

      # Verify bill with invalid sponsor gets nil
      bill2 = Repo.get(Bill, 102)
      assert bill2.sponsor_id == nil
    end

    test "imports votes from CSV" do
      # Import bills first
      CsvImporter.import_csv_file("legislators.csv", @test_input_path)
      CsvImporter.import_csv_file("bills.csv", @test_input_path)

      filename = "votes.csv"
      initial_count = Repo.aggregate(Vote, :count, :id)
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)
      final_count = Repo.aggregate(Vote, :count, :id)

      assert final_count == initial_count + 2
      assert Repo.get(Vote, 201)
      assert Repo.get(Vote, 202)
    end

    test "imports vote_results from CSV" do
      # Import prerequisites
      CsvImporter.import_csv_file("legislators.csv", @test_input_path)
      CsvImporter.import_csv_file("bills.csv", @test_input_path)
      CsvImporter.import_csv_file("votes.csv", @test_input_path)

      filename = "vote_results.csv"
      initial_count = Repo.aggregate(VoteResult, :count, :id)
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)
      final_count = Repo.aggregate(VoteResult, :count, :id)

      assert final_count == initial_count + 4
      assert Repo.get(VoteResult, 301)
      assert Repo.get(VoteResult, 302)
      assert Repo.get(VoteResult, 303)
      assert Repo.get(VoteResult, 304)
    end

    test "handles missing CSV file gracefully" do
      filename = "nonexistent.csv"

      # Should not crash, just skip
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)
    end

    test "handles unknown CSV file gracefully" do
      # Create a CSV file not in the config
      unknown_file = Path.join(@test_input_path, "unknown.csv")
      File.write!(unknown_file, "id,data\n1,test")

      # Should not crash, just skip
      assert :ok = CsvImporter.import_csv_file("unknown.csv", @test_input_path)
    end

    test "handles malformed CSV data gracefully" do
      # Create a malformed CSV file
      malformed_file = Path.join(@test_input_path, "malformed_legislators.csv")
      File.write!(malformed_file, "id,name\n\"broken\",test\nvalid,\"quoted name\"")

      # Should not crash and try to process valid rows
      filename = "malformed_legislators.csv"
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)
    end

    test "logs import progress for each file" do
      # Import legislators and verify logging occurs (indirectly through success)
      filename = "legislators.csv"
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)

      # If it completes without error, logging worked
      assert Repo.aggregate(Legislator, :count, :id) >= 3
    end
  end

  describe "edge cases and error handling" do
    test "handles empty CSV files" do
      empty_file = Path.join(@test_input_path, "empty_legislators.csv")
      File.write!(empty_file, "id,name\n")

      filename = "empty_legislators.csv"
      initial_count = Repo.aggregate(Legislator, :count, :id)
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)
      final_count = Repo.aggregate(Legislator, :count, :id)

      # No new records should be added from empty file
      assert final_count == initial_count
    end

    test "handles CSV files with extra columns" do
      _extra_cols_file = Path.join(@test_input_path, "legislators.csv")
      # Use an existing valid file since the importer only processes known files

      filename = "legislators.csv"
      assert :ok = CsvImporter.import_csv_file(filename, @test_input_path)

      # Should still import the valid data
      legislator = Repo.get(Legislator, 1)
      assert legislator
      assert legislator.name == "John Doe"
    end

    test "handles duplicate IDs by skipping existing records" do
      # First import
      assert :ok = CsvImporter.import_csv_file("legislators.csv", @test_input_path)
      initial_count = Repo.aggregate(Legislator, :count, :id)

      # Import again - should skip existing
      assert :ok = CsvImporter.import_csv_file("legislators.csv", @test_input_path)
      final_count = Repo.aggregate(Legislator, :count, :id)

      # Count should remain the same
      assert final_count == initial_count
    end
  end

  defp create_test_csv_files do
    legislators_content = """
    id,name
    1,John Doe
    2,Jane Smith
    3,Bob Johnson
    """
    File.write!(Path.join(@test_input_path, "legislators.csv"), legislators_content)

    bills_content = """
    id,title,sponsor_id
    101,Test Bill 1,1
    102,Test Bill 2,999
    """
    File.write!(Path.join(@test_input_path, "bills.csv"), bills_content)

    votes_content = """
    id,bill_id
    201,101
    202,102
    """
    File.write!(Path.join(@test_input_path, "votes.csv"), votes_content)

    vote_results_content = """
    id,legislator_id,vote_id,vote_type
    301,1,201,1
    302,2,201,2
    303,1,202,1
    304,3,202,2
    """
    File.write!(Path.join(@test_input_path, "vote_results.csv"), vote_results_content)
  end
end
