defmodule ApiWeb.BlogPostActions do
  use Api.Web, :action

  alias ApiWeb.{BlogPost, Repo}

  def all do
    Repo.all(BlogPost)
    |> Repo.preload(:user)
  end

  def get(id) do
    Repo.get_by!(BlogPost, slug: id)
    |> Repo.preload(:user)
  end

  def create(user, blogpost_params) do
    changeset = BlogPost.changeset(%BlogPost{user_id: user.id}, blogpost_params)

    case Repo.insert(changeset) do
      {:ok, blogpost} -> {:ok, blogpost |> Repo.preload(:user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(id, blogpost_params) do
    blogpost = Repo.get_by!(BlogPost, slug: id)
    changeset = BlogPost.changeset(blogpost, blogpost_params)

    case Repo.update(changeset) do
      {:ok, blogpost} -> {:ok, blogpost |> Repo.preload(:user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete(id) do
    blogpost = Repo.get_by!(BlogPost, slug: id)
    Repo.delete!(blogpost)
  end
end
