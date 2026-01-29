defmodule QuorumCodingChallenge.CsvImporter do
  @moduledoc """
  Module for importing CSV data into the database.
  Dynamically reads CSV files from the tables folder and imports them.
  """

  alias QuorumCodingChallenge.Repo
  alias QuorumCodingChallenge.Schemas.{Legislator, Bill, Vote, VoteResult}

  @tables_path Path.join([__DIR__, "..", "..", "tables"])

  # Mapping of CSV files to schemas and their column mappings
  @import_config %{
    "legislators.csv" => %{
      schema: Legislator,
      columns: [:id, :name],
      dependencies: []
    },
    "bills.csv" => %{
      schema: Bill,
      columns: [:id, :title, :sponsor_id],
      dependencies: ["legislators.csv"]
    },
    "votes.csv" => %{
      schema: Vote,
      columns: [:id, :bill_id],
      dependencies: ["legislators.csv", "bills.csv"]
    },
    "vote_results.csv" => %{
      schema: VoteResult,
      columns: [:id, :legislator_id, :vote_id, :vote_type],
      dependencies: ["legislators.csv", "bills.csv", "votes.csv"]
    }
  }

  @doc """
  Import all CSV files in the correct order based on dependencies.
  """
  def import_all(custom_path \\ nil) do
    tables_path = custom_path || @tables_path

    import_order = get_import_order()

    Enum.each(import_order, fn filename ->
      import_csv_file(filename, tables_path)
    end)
  end

  @doc """
  Import a specific CSV file.
  """
  def import_csv_file(filename, custom_path \\ nil) do
    config = @import_config[filename]
    if config do
      tables_path = custom_path || @tables_path
      file_path = Path.join(tables_path, filename)

      if File.exists?(file_path) do
        unless Mix.env() == :test do
          IO.puts("Importing #{filename}...")
        end
        initial_count = Repo.aggregate(config.schema, :count, :id)

        file_path
        |> File.stream!()
        |> CSV.decode(headers: true)
        |> Enum.each(fn {:ok, row} ->
          insert_row(config.schema, config.columns, row)
        end)

        final_count = Repo.aggregate(config.schema, :count, :id)
        new_records = final_count - initial_count
        unless Mix.env() == :test do
          IO.puts("  #{new_records} new records added (total: #{final_count})")
        end
      else
        unless Mix.env() == :test do
          IO.puts("Warning: #{filename} not found at #{file_path}")
        end
      end
    else
      unless Mix.env() == :test do
        IO.puts("Warning: No configuration found for #{filename}")
      end
    end

    :ok
  end

  @doc """
  Get available CSV files in the tables directory.
  """
  def get_available_files do
    if File.exists?(@tables_path) do
      @tables_path
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".csv"))
      |> Enum.sort()
    else
      []
    end
  end

  # Private functions

  defp get_import_order do
    # Sort files based on their dependencies
    files = Map.keys(@import_config)
    sort_by_dependencies(files, @import_config)
  end

  defp sort_by_dependencies(files, config) do
    # Simple dependency sorting - files with no dependencies first
    Enum.sort_by(files, fn file ->
      length(config[file].dependencies)
    end)
  end

  defp insert_row(schema, columns, row) do
    attrs =
      columns
      |> Enum.reduce(%{}, fn column, acc ->
        # Convert atom column name to string to match CSV headers
        column_name = Atom.to_string(column)
        value = Map.get(row, column_name)
        processed_value = process_value(column, value)
        Map.put(acc, column, processed_value)
      end)
      |> validate_foreign_keys()

    # Check if record already exists by ID
    case Repo.get(schema, attrs[:id]) do
      nil ->
        # Record doesn't exist, insert it
        changeset = schema.changeset(struct(schema), attrs)
        Repo.insert!(changeset)
      _existing ->
        # Record exists, skip it (or could update if needed)
        :ok
    end
  end

  defp validate_foreign_keys(attrs) do
    attrs
    |> validate_foreign_key(:sponsor_id, Legislator)
    |> validate_foreign_key(:legislator_id, Legislator)
    |> validate_foreign_key(:bill_id, Bill)
    |> validate_foreign_key(:vote_id, Vote)
  end

  defp validate_foreign_key(attrs, key, schema) do
    case Map.get(attrs, key) do
      nil -> attrs
      id when is_integer(id) ->
        case Repo.get(schema, id) do
          nil ->
            unless Mix.env() == :test do
              IO.puts("Warning: #{key} #{id} not found, setting to nil")
            end
            Map.put(attrs, key, nil)
          _exists -> attrs
        end
      _ -> attrs
    end
  end

  defp process_value(column, value) when column in [:id, :legislator_id, :vote_id, :bill_id, :sponsor_id, :vote_type] do
    case value do
      "" -> nil
      nil -> nil
      val when is_binary(val) -> String.to_integer(val)
      val -> val
    end
  end

  defp process_value(_column, value), do: value
end
