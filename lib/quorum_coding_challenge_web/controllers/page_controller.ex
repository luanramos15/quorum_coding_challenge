defmodule QuorumCodingChallengeWeb.PageController do
  use QuorumCodingChallengeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
