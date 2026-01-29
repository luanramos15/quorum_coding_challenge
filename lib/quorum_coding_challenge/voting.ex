defmodule QuorumCodingChallenge.Voting do
  @moduledoc """
  The Voting context for handling legislators, bills, votes, and vote results.

  Vote types:
  - 1 = yea (in favor)
  - 2 = nay (opposed)
  """

  import Ecto.Query, warn: false
  alias QuorumCodingChallenge.Repo

  alias QuorumCodingChallenge.Schemas.{Legislator, Bill, Vote, VoteResult}

  @doc """
  Returns the list of legislators.
  """
  def list_legislators do
    Repo.all(Legislator)
  end

  @doc """
  Gets a single legislator.
  """
  def get_legislator!(id), do: Repo.get!(Legislator, id)

  @doc """
  Returns the list of bills.
  """
  def list_bills do
    Repo.all(Bill)
    |> Repo.preload(:sponsor)
  end

  @doc """
  Gets a single bill.
  """
  def get_bill!(id) do
    Repo.get!(Bill, id)
    |> Repo.preload(:sponsor)
  end

  @doc """
  Returns the list of votes.
  """
  def list_votes do
    Repo.all(Vote)
    |> Repo.preload(:bill)
  end

  @doc """
  Gets a single vote.
  """
  def get_vote!(id) do
    Repo.get!(Vote, id)
    |> Repo.preload([:bill, :vote_results])
  end

  @doc """
  Returns vote results for a specific vote.
  """
  def get_vote_results_for_vote(vote_id) do
    from(vr in VoteResult,
      join: l in Legislator, on: vr.legislator_id == l.id,
      where: vr.vote_id == ^vote_id,
      select: %{
        legislator_name: l.name,
        vote_type: vr.vote_type
      }
    )
    |> Repo.all()
  end

  @doc """
  Returns a summary of votes on a bill.
  """
  def get_bill_vote_summary(bill_id) do
    from(vr in VoteResult,
      join: v in Vote, on: vr.vote_id == v.id,
      where: v.bill_id == ^bill_id,
      group_by: vr.vote_type,
      select: %{vote_type: vr.vote_type, count: count(vr.id)}
    )
    |> Repo.all()
  end

  @doc """
  Gets a legislator's voting record.
  """
  def get_legislator_votes(legislator_id) do
    from(vr in VoteResult,
      join: l in Legislator, on: vr.legislator_id == l.id,
      join: v in Vote, on: vr.vote_id == v.id,
      join: b in Bill, on: v.bill_id == b.id,
      where: l.id == ^legislator_id,
      select: %{
        bill_title: b.title,
        vote_type: vr.vote_type,
        vote_id: v.id
      }
    )
    |> Repo.all()
  end

  @doc """
  Returns legislators who voted on opposing sides of an issue.
  """
  def get_opposing_votes(bill_id) do
    from(vr in VoteResult,
      join: l in Legislator, on: vr.legislator_id == l.id,
      join: v in Vote, on: vr.vote_id == v.id,
      where: v.bill_id == ^bill_id,
      select: %{
        legislator_name: l.name,
        legislator_id: l.id,
        vote_type: vr.vote_type
      },
      order_by: [asc: vr.vote_type, asc: l.name]
    )
    |> Repo.all()
  end

  @doc """
  Get legislators who voted yea on a bill.
  """
  def get_yea_votes(bill_id) do
    get_votes_by_type(bill_id, VoteResult.vote_type_yea())
  end

  @doc """
  Get legislators who voted nay on a bill.
  """
  def get_nay_votes(bill_id) do
    get_votes_by_type(bill_id, VoteResult.vote_type_nay())
  end

  @doc """
  Get legislators by vote type for a bill.
  """
  def get_votes_by_type(bill_id, vote_type) do
    from(vr in VoteResult,
      join: l in Legislator, on: vr.legislator_id == l.id,
      join: v in Vote, on: vr.vote_id == v.id,
      where: v.bill_id == ^bill_id and vr.vote_type == ^vote_type,
      select: %{
        legislator_name: l.name,
        legislator_id: l.id,
        vote_type: vr.vote_type
      },
      order_by: l.name
    )
    |> Repo.all()
  end

  @doc """
  Get vote summary with human-readable labels.
  """
  def get_bill_vote_summary_with_labels(bill_id) do
    summary = get_bill_vote_summary(bill_id)

    Enum.map(summary, fn %{vote_type: vote_type, count: count} ->
      %{
        vote_type: vote_type,
        vote_label: VoteResult.vote_type_to_string(vote_type),
        count: count
      }
    end)
  end
end
