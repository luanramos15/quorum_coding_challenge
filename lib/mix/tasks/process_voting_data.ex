defmodule Mix.Tasks.ProcessVotingData do
  @moduledoc """
  Import CSV data and generate voting analysis reports.

  Usage: mix process_voting_data

  This task will:
  1. Import CSV files from tables/input/ folder
  2. Generate legislators-support-oppose-count.csv
  3. Generate bills.csv with voting summaries
  """

  use Mix.Task

  alias QuorumCodingChallenge.{CsvImporter, Voting}


  @shortdoc "Import CSV data and generate voting analysis reports"

  def run(_args) do
    Mix.Task.run("app.start")

    # Clean up and ensure output directory exists
    IO.puts("🧹 Cleaning up existing output files...")
    File.rm_rf!("tables/output")
    File.mkdir_p!("tables/output")

    # Import CSV data
    IO.puts("🔄 Importing CSV data...")
    CsvImporter.import_all("tables/input")
    IO.puts("✅ Data import completed")

    # Generate reports
    IO.puts("🔄 Generating legislator support/oppose report...")
    generate_legislator_report()

    IO.puts("🔄 Generating bills report...")
    generate_bills_report()

    IO.puts("✅ All reports generated successfully!")
    IO.puts("📁 Check tables/output/ for the generated CSV files")
  end

  defp generate_legislator_report do
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

    # Write to CSV file
    csv_content = all_csv_data
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")

    File.write!("tables/output/legislators-support-oppose-count.csv", csv_content)
    IO.puts("  ✓ Generated tables/output/legislators-support-oppose-count.csv")
  end

  defp generate_bills_report do
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

    # Write to CSV file
    csv_content = all_csv_data
    |> Enum.map(&format_csv_row/1)
    |> Enum.join("\n")

    File.write!("tables/output/bills.csv", csv_content)
    IO.puts("  ✓ Generated tables/output/bills.csv")
  end

  # Helper function to properly format CSV rows (handle commas in titles)
  defp format_csv_row(row) do
    row
    |> Enum.map(&escape_csv_field/1)
    |> Enum.join(",")
  end

  # Escape CSV fields that contain commas or quotes
  defp escape_csv_field(field) when is_binary(field) do
    if String.contains?(field, [",", "\"", "\n"]) do
      "\"#{String.replace(field, "\"", "\"\"")}\""
    else
      field
    end
  end

  defp escape_csv_field(field), do: to_string(field)
end
