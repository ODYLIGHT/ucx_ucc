defmodule UcxUccWeb.Coherence.InvitationController do
  @moduledoc """
  Handle invitation actions.

  Handle the following actions:

  * new - render the send invitation form.
  * create - generate and send the invitation token.
  * edit - render the form after user clicks the invitation email link.
  * create_user - create a new user database record
  * resend - resend an invitation token email
  """
  use CoherenceWeb, :controller
  use Timex

  import Ecto.Changeset

  alias Coherence.{Config, Messages}
  alias UcxUcc.Coherence.Schemas
  alias UcxUcc.Accounts

  require Logger

  plug Coherence.ValidateOption, :invitable
  plug :scrub_params, "user" when action in [:create_user]
  plug :layout_view, view: Coherence.InvitationView, caller: __MODULE__

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  @doc """
  Render the new invitation form.
  """
  @spec new(conn, params) :: conn
  def new(conn, _params) do
    changeset = Schemas.change_invitation()
    render(conn, "new.html", changeset: changeset)
  end

  @doc """
  Generate and send an invitation token.

  Creates a new invitation token, save it to the database and send
  the invitation email.
  """
  @spec create(conn, params) :: conn
  def create(conn, %{"invitation" =>  invitation_params} = params) do
    email = invitation_params["email"]
    changeset = Schemas.change_invitation invitation_params
    # case repo.one from u in user_schema, where: u.email == ^email do
    case Schemas.get_user_by_email email do
      nil ->
        token = random_string 48
        url = router_helpers().invitation_url(conn, :edit, token)
        changeset = put_change(changeset, :token, token)
        do_insert(conn, changeset, url, params, email)
      _ ->
        changeset =
          changeset
          |> add_error(:email, Messages.backend().user_already_has_an_account())
          |> struct(action: true)
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp do_insert(conn, changeset, url, params, email) do
    case Schemas.create changeset do
      {:ok, invitation} ->
        send_user_email :invitation, invitation, url
        conn
        |> put_flash(:info, Messages.backend().invitation_sent())
        |> redirect_to(:invitation_create, params)
      {:error, changeset} ->
        {conn, changeset} =
          case Schemas.get_by_invitation email: email do
            nil -> {conn, changeset}
            invitation ->
              {assign(conn, :invitation, invitation),
                add_error(changeset, :email,
                  Messages.backend().invitation_already_sent())}
          end
        render(conn, "new.html", changeset: changeset)
    end
  end

  @doc """
  Render the create user template.

  Sets the name and email address in the form based on what was entered
  when the invitation was sent.
  """
  @spec edit(conn, params) :: conn
  def edit(conn, params) do
    token = params["id"]
    case Schemas.get_by_invitation token: token do
      nil ->
        conn
        |> put_flash(:error, Messages.backend().invalid_invitation_token())
        |> redirect(to: logged_out_url(conn))
      invite ->
        user_schema = Config.user_schema
        changeset = Controller.changeset(:invitation, user_schema, user_schema.__struct__,
          %{email: invite.email, name: invite.name})
        conn
        |> render(:edit, changeset: changeset, token: invite.token)
    end
  end

  @doc """
  Create a new user action.

  Create a new user based from an invite token.
  """
  @spec create_user(conn, params) :: conn
  def create_user(conn, params) do
    token = params["token"]
    user_schema = Config.user_schema
    case Schemas.get_by_invitation token: token do
      nil ->
        conn
        |> put_flash(:error, Messages.backend().invalid_invitation())
        |> redirect(to: logged_out_url(conn))
      invite ->
        case Accounts.create_user params["user"] do
          {:ok, user} ->
            Accounts.add_role_to_user user, "user"
            Schemas.delete invite
            conn
            |> send_confirmation(user, user_schema)
            |> redirect(to: logged_out_url(conn))
          {:error, changeset} ->
            render conn, "edit.html", changeset: changeset, token: token
        end
    end
  end

  @doc """
  Resent an invitation

  Resent the invitation based on the invitation's id.
  """
  @spec resend(conn, params) :: conn
  def resend(conn, %{"id" => id} = params) do
    conn =
      case Schemas.get_invitation id do
        nil ->
          put_flash(conn, :error, Messages.backend().cant_find_that_token())
        invitation ->
          send_user_email :invitation, invitation,
            router_helpers().invitation_url(conn, :edit, invitation.token)
          put_flash conn, :info, Messages.backend().invitation_sent()
      end
    redirect_to(conn, :invitation_resend, params)
  end
end
