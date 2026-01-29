defmodule QuorumCodingChallenge.Repo do
  use Ecto.Repo,
    otp_app: :quorum_coding_challenge,
    adapter: Ecto.Adapters.Postgres
end
