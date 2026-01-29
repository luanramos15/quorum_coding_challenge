# Quorum Coding Challenge - Legislative Voting Data Analysis

A Phoenix web application that processes legislative voting data from CSV files and generates comprehensive voting analysis reports.

## 📊 Project Overview

This application analyzes legislative voting patterns by processing CSV data about legislators, bills, votes, and voting results. It provides insights into legislator support/opposition patterns and bill voting summaries.

### Key Features

- **Dynamic CSV Import**: Automatically imports legislative data from CSV files
- **Voting Analysis**: Generates detailed reports on legislator and bill voting patterns  
- **SQLite Database**: Lightweight database with proper relational structure
- **Foreign Key Validation**: Handles missing data gracefully with validation
- **Mix Task Integration**: Command-line tool for data processing

## 🚀 Quick Start

### Prerequisites

- Elixir 1.17+ (recommended: 1.17.3 for best compatibility)
- Phoenix Framework
- SQLite3

### Installation

1. **Clone and setup the project:**
   ```bash
   git clone <repository-url>
   cd quorum_coding_challenge
   mix setup
   ```

2. **Create the database:**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

3. **Process voting data:**
   ```bash
   mix process_voting_data
   ```

## 🔧 Using the Data Processing Task

### Command
```bash
mix process_voting_data
```

### What it does:
1. **🧹 Cleans output directory** - Removes existing report files
2. **📥 Imports CSV data** - Processes files from `tables/input/` folder
3. **📊 Generates analysis reports** in `tables/output/`:
   - `legislators-support-oppose-count.csv`
   - `bills.csv`

### Input Data Structure

Place your CSV files in the `tables/input/` directory with the following structure:

#### `legislators.csv`
```csv
id,name
1,John Doe
2,Jane Smith
```

#### `bills.csv`
```csv
id,title,sponsor_id
101,Healthcare Reform Act,1
102,Education Funding Bill,2
```

#### `votes.csv`
```csv
id,bill_id
1001,101
1002,102
```

#### `vote_results.csv`
```csv
id,legislator_id,vote_id,vote_type
1,1,1001,1
2,2,1001,2
```

**Vote Types:**
- `1` = Yea (support)
- `2` = Nay (oppose)

### Output Reports

#### `legislators-support-oppose-count.csv`
Shows voting patterns for each legislator:
```csv
id,name,num_supported_bills,num_opposed_bills
1,John Doe,5,3
2,Jane Smith,8,1
```

#### `bills.csv`
Shows voting summaries for each bill:
```csv
id,title,supporter_count,opposer_count,primary_sponsor
101,Healthcare Reform Act,12,8,John Doe
102,Education Funding Bill,15,5,Unknown
```

## 🏗️ Database Schema

The application uses a relational SQLite database with four main tables:

- **`legislators`** - Legislator information (id, name)
- **`bills`** - Bill details with sponsor relationships
- **`votes`** - Voting sessions linked to bills
- **`vote_results`** - Individual legislator votes with type validation

## 🧪 Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover | grep -E "(Percentage|---|QuorumCodingChallenge\.|Mix\.Tasks\.)" | grep -v "Web"

# Run specific test file
mix test test/mix/tasks/process_voting_data_test.exs
```

## 🔄 Development Workflow

1. **Add new CSV data** to `tables/input/`
2. **Run the processing task** to import and analyze
3. **Check generated reports** in `tables/output/`
4. **Run tests** to ensure everything works correctly

```bash
mix process_voting_data
mix test
mix precommit  # Runs formatting, credo, and tests
```

## 📁 Project Structure

```
lib/
├── quorum_coding_challenge/
│   ├── schemas/              # Ecto schemas for data models
│   ├── csv_importer.ex      # Dynamic CSV import system
│   └── voting.ex            # Business logic context
├── mix/tasks/
│   └── process_voting_data.ex  # Main data processing task
test/
├── quorum_coding_challenge/    # Schema and context tests
└── mix/tasks/                  # Task integration tests
tables/
├── input/                      # Source CSV files
└── output/                     # Generated reports (gitignored)
```

## 🛠️ Key Technologies

- **Phoenix Framework** - Web application framework
- **Ecto** - Database wrapper and query generator
- **SQLite3** - Lightweight database
- **NimbleCSV** - Fast CSV parsing
- **ExUnit** - Testing framework