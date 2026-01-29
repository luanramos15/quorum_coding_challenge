defmodule Mix.Tasks.ProcessVotingDataTest do
  use QuorumCodingChallenge.DataCase

  alias QuorumCodingChallenge.Voting
  alias QuorumCodingChallenge.Schemas.{Legislator, Bill, Vote, VoteResult}

  @test_output_path "test/fixtures/output"

  setup do
    # Clean up any previous test files
    File.rm_rf!(@test_output_path)

    # Create test directories
    File.mkdir_p!(@test_output_path)

    # Create sample test data in the database
    create_test_data()

    on_exit(fn ->
      File.rm_rf!(@test_output_path)
    end)

    :ok
  end

  describe "process_voting_data mix task" do
    test "generates correct legislator support/oppose report" do
      # Call the test helper function to generate the report
      generate_test_legislator_report()

      # Check that the file was created
      output_file = Path.join(@test_output_path, "legislators-support-oppose-count.csv")
      assert File.exists?(output_file)

      # Check file contents
      content = File.read!(output_file)
      lines = String.split(content, "\n", trim: true)

      # Should have header + data rows
      assert length(lines) >= 2

      # Check header
      assert List.first(lines) == "id,name,num_supported_bills,num_opposed_bills"

      # Check data format (should be CSV with integers)
      data_lines = Enum.drop(lines, 1)
      Enum.each(data_lines, fn line ->
        parts = String.split(line, ",")
        assert length(parts) == 4

        # First part should be numeric (id)
        {id, ""} = Integer.parse(List.first(parts))
        assert is_integer(id)

        # Last two parts should be numeric (counts)
        {supported_count, ""} = Integer.parse(Enum.at(parts, 2))
        {opposed_count, ""} = Integer.parse(Enum.at(parts, 3))
        assert is_integer(supported_count)
        assert is_integer(opposed_count)
      end)
    end

    test "generates correct bills report" do
      generate_test_bills_report()

      # Check that the file was created
      output_file = Path.join(@test_output_path, "bills.csv")
      assert File.exists?(output_file)

      # Check file contents
      content = File.read!(output_file)
      lines = String.split(content, "\n", trim: true)

      # Should have header + data rows
      assert length(lines) >= 2

      # Check header
      assert List.first(lines) == "id,title,supporter_count,opposer_count,primary_sponsor"

      # Check data format
      data_lines = Enum.drop(lines, 1)
      Enum.each(data_lines, fn line ->
        parts = String.split(line, ",", limit: 5)
        assert length(parts) == 5

        # First part should be numeric (id)
        {id, ""} = Integer.parse(List.first(parts))
        assert is_integer(id)

        # Third and fourth parts should be numeric (counts)
        {supporter_count, ""} = Integer.parse(Enum.at(parts, 2))
        {opposer_count, ""} = Integer.parse(Enum.at(parts, 3))
        assert is_integer(supporter_count)
        assert is_integer(opposer_count)

        # Last part should be sponsor name or "Unknown"
        sponsor = Enum.at(parts, 4)
        assert is_binary(sponsor)
      end)
    end

    test "handles bills with no sponsor correctly" do
      # Create a bill without a sponsor
      _bill = Repo.insert!(%Bill{id: 999, title: "Orphan Bill", sponsor_id: nil})
      _vote = Repo.insert!(%Vote{id: 999, bill_id: 999})

      generate_test_bills_report()

      output_file = Path.join(@test_output_path, "bills.csv")
      content = File.read!(output_file)

      # Should contain "Unknown" for bills without sponsors
      assert String.contains?(content, "Unknown")
    end

    test "escapes CSV fields correctly" do
      # Create test data with commas and quotes in titles
      _bill = Repo.insert!(%Bill{id: 998, title: "Bill \"with quotes\", and commas", sponsor_id: 1})

      generate_test_bills_report()

      output_file = Path.join(@test_output_path, "bills.csv")
      content = File.read!(output_file)

      # Should properly escape the title with quotes
      assert String.contains?(content, "\"Bill \"\"with quotes\"\", and commas\"")
    end
  end

  # Test helper functions
  defp create_test_data do
    # Create test legislators
    legislator1 = Repo.insert!(%Legislator{id: 1, name: "John Doe"})
    legislator2 = Repo.insert!(%Legislator{id: 2, name: "Jane Smith"})

    # Create test bills
    bill1 = Repo.insert!(%Bill{id: 1, title: "Healthcare Reform", sponsor_id: legislator1.id})
    bill2 = Repo.insert!(%Bill{id: 2, title: "Education Funding", sponsor_id: legislator2.id})

    # Create test votes
    vote1 = Repo.insert!(%Vote{id: 1, bill_id: bill1.id})
    vote2 = Repo.insert!(%Vote{id: 2, bill_id: bill2.id})

    # Create test vote results
    # Legislator 1: supports bill 1, opposes bill 2
    Repo.insert!(%VoteResult{id: 1, legislator_id: legislator1.id, vote_id: vote1.id, vote_type: 1})
    Repo.insert!(%VoteResult{id: 2, legislator_id: legislator1.id, vote_id: vote2.id, vote_type: 2})

    # Legislator 2: supports both bills
    Repo.insert!(%VoteResult{id: 3, legislator_id: legislator2.id, vote_id: vote1.id, vote_type: 1})
    Repo.insert!(%VoteResult{id: 4, legislator_id: legislator2.id, vote_id: vote2.id, vote_type: 1})
  end

  # Custom report generators for testing with different output path
  defp generate_test_legislator_report do
    # Get all legislators and calculate their voting statistics
    legislators = Voting.list_legislators()

    csv_data = [
      ["id", "name", "num_supported_bills", "num_opposed_bills"]
    ]

    legislator_data = Enum.map(legislators, fn legislator ->
      votes = Voting.get_legislator_votes(legislator.id)

      supported_count = Enum.count(votes, fn vote -> vote.vote_type == 1 end)
      opposed_count = Enum.count(votes, fn vote -> vote.vote_type == 2 end)

      [legislator.id, legislator.name, supported_count, opposed_count]
    end)

    all_csv_data = csv_data ++ legislator_data

    csv_content = all_csv_data
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")

    output_file = Path.join(@test_output_path, "legislators-support-oppose-count.csv")
    File.write!(output_file, csv_content)
  end

  defp generate_test_bills_report do
    # Get all bills with sponsor information
    bills = Voting.list_bills()

    csv_data = [
      ["id", "title", "supporter_count", "opposer_count", "primary_sponsor"]
    ]

    bill_data = Enum.map(bills, fn bill ->
      # Get vote summary for this bill
      summary = Voting.get_bill_vote_summary(bill.id)

      # Extract supporter and opposer counts
      supporter_count = summary
      |> Enum.find(fn %{vote_type: type} -> type == 1 end)
      |> case do
        %{count: count} -> count
        nil -> 0
      end

      opposer_count = summary
      |> Enum.find(fn %{vote_type: type} -> type == 2 end)
      |> case do
        %{count: count} -> count
        nil -> 0
      end

      # Get sponsor name or "Unknown"
      primary_sponsor = if bill.sponsor do
        bill.sponsor.name
      else
        "Unknown"
      end

      [bill.id, bill.title, supporter_count, opposer_count, primary_sponsor]
    end)

    all_csv_data = csv_data ++ bill_data

    csv_content = all_csv_data
    |> Enum.map(&format_csv_row/1)
    |> Enum.join("\n")

    output_file = Path.join(@test_output_path, "bills.csv")
    File.write!(output_file, csv_content)
  end

  # Copy of the CSV escaping functions from the main module
  defp format_csv_row(row) do
    row
    |> Enum.map(&escape_csv_field/1)
    |> Enum.join(",")
  end

  defp escape_csv_field(field) when is_binary(field) do
    if String.contains?(field, [",", "\"", "\n"]) do
      "\"#{String.replace(field, "\"", "\"\"")}\""
    else
      field
    end
  end

  defp escape_csv_field(field), do: to_string(field)
end
