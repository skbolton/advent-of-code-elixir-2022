defmodule AdventOfCode.Day14 do
  def part1(input) do
    input
    |> build_cave()
    |> run(_turn = 0)
    |> Kernel.-(1)
  end

  def build_cave(stones) do
    cave = %{
      obstacles: MapSet.new(),
      floor: nil,
      over?: false
    }

    stones
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> String.replace(" -> ", ",")
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
      |> Enum.chunk_every(2)
    end)
    |> Enum.reduce(cave, fn line, cave ->
      Enum.reduce(line, {cave, _prev_point = nil}, fn
        # first run where previous point isn't known yet (we are looking at it)
        [x, y], {cave, nil} ->
          {cave, {x, y}}

        [x, y], {cave, from} ->
          {add_stone_path(cave, from, {x, y}), {x, y}}
      end)
      |> elem(0)
    end)
    |> find_floor()
  end

  def place_stone(cave, point) do
    %{cave | obstacles: MapSet.put(cave.obstacles, point)}
  end

  def open?(%{floor: floor}, {_x, floor}) do
    false
  end

  def open?(cave, point) do
    not MapSet.member?(cave.obstacles, point)
  end

  def part2(input) do
    input
    |> build_cave()
    # floor is now lower based on part 2
    |> Map.update!(:floor, &Kernel.+(&1, 2))
    |> run2(_turn = 0)
  end

  def drop_sand2(cave, {x, y} = point) do
    down = {x, min(y + 1, cave.floor)}
    left = {x - 1, min(y + 1, cave.floor)}
    right = {x + 1, min(y + 1, cave.floor)}

    cond do
      open?(cave, down) ->
        drop_sand2(cave, down)

      open?(cave, left) ->
        drop_sand2(cave, left)

      open?(cave, right) ->
        drop_sand2(cave, right)

      # sand settled
      x == 500 and y == 0 ->
        %{cave | over?: true}

      true ->
        Map.update!(cave, :obstacles, &MapSet.put(&1, point))
    end
  end

  def run(%{over?: true}, turn) do
    turn
  end

  def run(cave, turn) do
    cave
    |> drop_sand({500, 0})
    |> run(turn + 1)
  end

  def run2(%{over?: true}, turn) do
    turn
  end

  def run2(cave, turn) do
    cave
    |> drop_sand2({500, 0})
    |> run2(turn + 1)
  end

  def drop_sand(cave, {x, y} = point) do
    down = {x, y + 1}
    left = {x - 1, y + 1}
    right = {x + 1, y + 1}

    cond do
      beneath_floor?(cave, point) ->
        %{cave | over?: true}

      open?(cave, down) ->
        drop_sand(cave, down)

      open?(cave, left) ->
        drop_sand(cave, left)

      open?(cave, right) ->
        drop_sand(cave, right)

      # sand settled
      true ->
        Map.update!(cave, :obstacles, &MapSet.put(&1, point))
    end
  end

  def beneath_floor?(%{floor: floor}, {_x, y}) do
    y >= floor
  end

  # horizontal path
  def add_stone_path(cave, {x, from_y}, {x, to_y}) do
    Range.new(min(from_y, to_y), max(from_y, to_y))
    |> Enum.reduce(cave, fn y_coordinate, cave ->
      place_stone(cave, {x, y_coordinate})
    end)
  end

  # vertical path
  def add_stone_path(cave, {from_x, y}, {to_x, y}) do
    Range.new(min(from_x, to_x), max(from_x, to_x))
    |> Enum.reduce(cave, fn x_coordinate, cave ->
      place_stone(cave, {x_coordinate, y})
    end)
  end

  def find_floor(cave) do
    floor =
      cave.obstacles
      |> MapSet.to_list()
      |> Enum.reduce(0, fn {_x, y}, lowest -> max(lowest, y) end)

    %{cave | floor: floor}
  end
end
