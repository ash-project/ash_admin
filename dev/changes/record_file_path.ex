# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Dev.Changes.RecordFilePath do
  use Ash.Resource.Change

  @impl true
  def init(opts) do
    if is_atom(opts[:file_attribute]) do
      if is_atom(opts[:path_attribute]) do
        {:ok, opts}
      else
        {:error, "path_attribute must be an atom!"}
      end
    else
      {:error, "file_attribute must be an atom!"}
    end
  end

  @impl true
  def change(changeset, opts, _context) do
    case Ash.Changeset.fetch_argument(changeset, opts[:file_attribute]) do
      {:ok, photo} ->
        Ash.Changeset.force_change_attribute(changeset, opts[:path_attribute], photo.source)

      :error -> changeset
    end
  end
end
