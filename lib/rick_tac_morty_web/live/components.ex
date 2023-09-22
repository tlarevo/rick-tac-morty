defmodule RickTacMortyWeb.Components do
  @moduledoc """
  Collection of components for rendering game elements.
  """
  use Phoenix.HTML
  alias RickTacMorty.GameState
  alias RickTacMorty.Player
  alias RickTacMorty.Cell

  def player_tile_color(%GameState{status: :done} = game, player, _local_player) do
    case GameState.result(game) do
      :draw ->
        "bg-gray-400"

      # If the winner is this player
      ^player ->
        "bg-green-400"

      # If the losing player
      %Player{} ->
        "bg-red-400"

      _else ->
        "bg-gray-400"
    end
  end

  def player_tile_color(%GameState{status: :playing} = game, player, local_player) do
    if GameState.player_turn?(game, player) do
      if player == local_player do
        "bg-green-400"
      else
        "bg-gray-400"
      end
    else
      "bg-gray-400"
    end
  end

  # When we don't have the game state yet (haven't upgraded page to LiveView)
  def cell(player, game, cell_name, opts \\ [])

  def cell(%Player{} = player, %GameState{status: :done} = game, cell_name, opts) do
    # If game state is :done, color the winning colors according to the player.
    # If this player won, color winning cells green. If opponent won, color
    # them red.

    # Get the local player's opponent for coloring
    opponent = GameState.opponent(game, player)

    winning_cells =
      case GameState.check_for_player_win(game, player) do
        :not_found -> []
        [_, _, _] = winning_spaces -> winning_spaces
      end

    losing_cells =
      case GameState.check_for_player_win(game, opponent) do
        :not_found -> []
        [_, _, _] = losing_spaces -> losing_spaces
      end

    color =
      cond do
        Enum.member?(winning_cells, cell_name) -> "bg-green-200"
        Enum.member?(losing_cells, cell_name) -> "bg-red-200"
        true -> "bg-white"
      end

    case GameState.find_cell(game, cell_name) do
      {:ok, sq} ->
        render_cell(sq.letter, color, opts)

      _not_found ->
        render_cell(nil, "bg-white", opts)
    end
  end

  def cell(%Player{} = _player, %GameState{status: :playing} = game, cell_name, opts) do
    # If game state is playing, no special colors applied
    case GameState.find_cell(game, cell_name) do
      {:ok, %Cell{} = cell} ->
        render_cell(cell.letter, "bg-white", opts)

      _not_found ->
        render_cell(nil, "bg-white", opts)
    end
  end

  def cell(_player, _game, _cell_name, _opts), do: nil

  def render_cell(letter, color, opts) do
    classes = "m-2 sm:m-4 w-full h-22 rounded-lg shadow #{color} cursor-pointer"

    Phoenix.HTML.Tag.content_tag :span, Keyword.merge(opts, class: classes) do
      case letter do
        nil ->
          Phoenix.HTML.raw({:safe, "&nbsp;"})

        letter ->
          letter
      end
    end
  end

  def result(%GameState{status: :done} = state) do
    text =
      case GameState.result(state) do
        :draw ->
          "Tie Game!"

        %Player{name: winner_name} ->
          "#{winner_name} Wins!"
      end

    ~E"""
    <div class="m-4 sm:m-8 text-3xl sm:text-6xl text-center text-green-700">
      <%= text %>
    </div>
    """
  end

  def result(%GameState{} = _state) do
    ~E"""

    """
  end
end
