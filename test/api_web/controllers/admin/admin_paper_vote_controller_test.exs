defmodule ApiWeb.Admin.PaperVoteControllerTest do
  use ApiWeb.ConnCase

  alias Api.Competitions
  alias Guardian.{Permissions}

  setup %{conn: conn} do
    admin = create_admin()
    c = create_category()
    pv = create_paper_vote(c, admin)

    m = create_user()
    t = create_team(m, create_competition())

    make_teams_eligible()
    Competitions.start_voting()

    {:ok, jwt, _} =
      Guardian.encode_and_sign(admin, :token, perms: %{admin: Permissions.max})

    {:ok, %{
      admin: admin,
      category: c,
      paper_vote: pv,
      member: m,
      team: t,
      conn:
        conn
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> put_req_header("content-type", "application/json")
    }}
  end

  # test "create", %{conn: conn, category: c, admin: a} do
  #   conn = post(conn, admin_paper_vote_path(conn, :create), %{
  #     category_name: c.name,
  #   })

  #   new_pv = Repo.one!(from(pv in PaperVote, offset: 1))
  #   assert json_response(conn, 200) == %{
  #     "annulled_at" => nil,
  #     "annulled_by_id" => nil,
  #     "category_id" => c.id,
  #     "category_name" => c.name,
  #     "created_by_id" => a.id,
  #     "id" => new_pv.id,
  #     "redeemed_at" => nil,
  #     "redeeming_admin_id" => nil,
  #     "redeeming_member_id" => nil,
  #     "team_id" => nil,
  #   }
  # end

  # test "show", %{conn: conn, paper_vote: pv, category: c, admin: a} do
  #   conn = get(conn, admin_paper_vote_path(conn, :show, pv.id))

  #   assert json_response(conn, 200) == %{
  #     "annulled_at" => nil,
  #     "annulled_by_id" => nil,
  #     "category_id" => c.id,
  #     "category_name" => c.name,
  #     "created_by_id" => a.id,
  #     "id" => pv.id,
  #     "redeemed_at" => nil,
  #     "redeeming_admin_id" => nil,
  #     "redeeming_member_id" => nil,
  #     "team_id" => nil,
  #   }
  # end

  # test "404", %{conn: conn} do
  #   assert_error_sent 404, fn ->
  #     get(conn, admin_paper_vote_path(conn, :show, "11111111-1111-1111-1111-111111111111"))
  #   end
  # end

  # test "redeem", %{conn: conn, paper_vote: pv, team: t, member: m, category: c, admin: a} do
  #   conn = post(conn, admin_paper_vote_path(conn, :redeem, pv.id), %{
  #     team_id: t.id,
  #     member_id: m.id,
  #   })

  #   pv = Repo.get!(PaperVote, pv.id)
  #   assert json_response(conn, 200) == %{
  #     "annulled_at" => nil,
  #     "annulled_by_id" => nil,
  #     "category_id" => c.id,
  #     "category_name" => c.name,
  #     "created_by_id" => a.id,
  #     "id" => pv.id,
  #     "redeemed_at" => DateTime.to_iso8601(pv.redeemed_at),
  #     "redeeming_admin_id" => a.id,
  #     "redeeming_member_id" => m.id,
  #     "team_id" => t.id,
  #   }
  # end

  # test "redeem error", %{conn: conn, paper_vote: pv, team: t, member: m} do
  #   Competitions.end_voting()

  #   conn = post(conn, admin_paper_vote_path(conn, :redeem, pv.id), %{
  #     team_id: t.id,
  #     member_id: m.id,
  #   })

  #   assert json_response(conn, 422) == %{"errors" => "Competition already ended"}
  # end

  # test "annul", %{conn: conn, paper_vote: pv, category: c, admin: a} do
  #   conn = post(conn, admin_paper_vote_path(conn, :annul, pv.id))

  #   pv = Repo.get!(PaperVote, pv.id)
  #   assert json_response(conn, 200) == %{
  #     "annulled_at" => DateTime.to_iso8601(pv.annulled_at),
  #     "annulled_by_id" => a.id,
  #     "category_id" => c.id,
  #     "category_name" => c.name,
  #     "created_by_id" => a.id,
  #     "id" => pv.id,
  #     "redeemed_at" => nil,
  #     "redeeming_admin_id" => nil,
  #     "redeeming_member_id" => nil,
  #     "team_id" => nil,
  #   }
  # end
end
