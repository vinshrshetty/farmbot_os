defmodule FarmbotCore.Celery.Compiler.AxisControl do
  alias FarmbotCore.Celery.Compiler

  # Compiles move_absolute
  def move_absolute(%{args: %{location: location,offset: offset,speed: speed}}, cs_scope) do
    [locx , locy , locz] = cs_to_xyz(location, cs_scope)
    [offx, offy, offz] = cs_to_xyz(offset, cs_scope)

    quote location: :keep do
        # Subtract the location from offset.
        # Note: list syntax here for readability.
        [x, y, z] = [
          unquote(locx) + unquote(offx),
          unquote(locy) + unquote(offy),
          unquote(locz) + unquote(offz)
        ]

        x_str = FarmbotCore.Celery.FormatUtil.format_float(x)
        y_str = FarmbotCore.Celery.FormatUtil.format_float(y)
        z_str = FarmbotCore.Celery.FormatUtil.format_float(z)

        FarmbotCore.Celery.SysCalls.log(
          "Moving to (#{x_str}, #{y_str}, #{z_str})",
          true
        )

        FarmbotCore.Celery.SysCalls.move_absolute(
          x,
          y,
          z,
          unquote(Compiler.celery_to_elixir(speed, cs_scope))
        )
    end
  end

  # compiles move_relative into move absolute
  def move_relative(%{args: %{x: x, y: y, z: z, speed: speed}}, cs_scope) do
    quote location: :keep do
      with locx when is_number(locx) <- unquote(Compiler.celery_to_elixir(x, cs_scope)),
           locy when is_number(locy) <- unquote(Compiler.celery_to_elixir(y, cs_scope)),
           locz when is_number(locz) <- unquote(Compiler.celery_to_elixir(z, cs_scope)),
           curx when is_number(curx) <-
             FarmbotCore.Celery.SysCalls.get_current_x(),
           cury when is_number(cury) <-
             FarmbotCore.Celery.SysCalls.get_current_y(),
           curz when is_number(curz) <-
             FarmbotCore.Celery.SysCalls.get_current_z() do
        # Combine them
        x = locx + curx
        y = locy + cury
        z = locz + curz
        x_str = FarmbotCore.Celery.FormatUtil.format_float(x)
        y_str = FarmbotCore.Celery.FormatUtil.format_float(y)
        z_str = FarmbotCore.Celery.FormatUtil.format_float(z)

        FarmbotCore.Celery.SysCalls.log(
          "Moving relative to (#{x_str}, #{y_str}, #{z_str})",
          true
        )

        FarmbotCore.Celery.SysCalls.move_absolute(
          x,
          y,
          z,
          unquote(Compiler.celery_to_elixir(speed, cs_scope))
        )
      end
    end
  end

  # Expands find_home(all) into three find_home/1 calls
  def find_home(%{args: %{axis: "all"}}, _cs_scope) do
    quote location: :keep do
      FarmbotCore.Celery.SysCalls.log("Finding home on all axes", true)

      with :ok <- FarmbotCore.Celery.SysCalls.find_home("z"),
           :ok <- FarmbotCore.Celery.SysCalls.find_home("y") do
        FarmbotCore.Celery.SysCalls.find_home("x")
      end
    end
  end

  # compiles find_home
  def find_home(%{args: %{axis: axis}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)) do
        FarmbotCore.Celery.SysCalls.log(
          "Finding home on the #{String.upcase(axis)} axis",
          true
        )

        FarmbotCore.Celery.SysCalls.find_home(axis)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Expands home(all) into three home/1 calls
  def home(%{args: %{axis: "all", speed: speed}}, cs_scope) do
    quote location: :keep do
      FarmbotCore.Celery.SysCalls.log("Going to home on all axes", true)

      with speed when is_number(speed) <-
             unquote(Compiler.celery_to_elixir(speed, cs_scope)),
           :ok <- FarmbotCore.Celery.SysCalls.home("z", speed),
           :ok <- FarmbotCore.Celery.SysCalls.home("y", speed) do
        FarmbotCore.Celery.SysCalls.home("x", speed)
      end
    end
  end

  # compiles home
  def home(%{args: %{axis: axis, speed: speed}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)),
           speed when is_number(speed) <-
             unquote(Compiler.celery_to_elixir(speed, cs_scope)) do
        FarmbotCore.Celery.SysCalls.log(
          "Going to home on the #{String.upcase(axis)} axis",
          true
        )

        FarmbotCore.Celery.SysCalls.home(axis, speed)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Expands zero(all) into three zero/1 calls
  def zero(%{args: %{axis: "all"}}, _cs_scope) do
    quote location: :keep do
      FarmbotCore.Celery.SysCalls.log("Setting home for all axes", true)

      with :ok <- FarmbotCore.Celery.SysCalls.zero("z"),
           :ok <- FarmbotCore.Celery.SysCalls.zero("y") do
        FarmbotCore.Celery.SysCalls.zero("x")
      end
    end
  end

  # compiles zero
  def zero(%{args: %{axis: axis}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)) do
        FarmbotCore.Celery.SysCalls.log(
          "Setting home for the #{String.upcase(axis)} axis",
          true
        )

        FarmbotCore.Celery.SysCalls.zero(axis)
      else
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Expands calibrate(all) into three calibrate/1 calls
  def calibrate(%{args: %{axis: "all"}}, _cs_scope) do
    quote location: :keep do
      FarmbotCore.Celery.SysCalls.log("Finding length of all axes", true)

      with :ok <- FarmbotCore.Celery.SysCalls.calibrate("z"),
           :ok <- FarmbotCore.Celery.SysCalls.calibrate("y") do
        FarmbotCore.Celery.SysCalls.calibrate("x")
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # compiles calibrate
  def calibrate(%{args: %{axis: axis}}, cs_scope) do
    quote location: :keep do
      with axis when axis in ["x", "y", "z"] <-
             unquote(Compiler.celery_to_elixir(axis, cs_scope)) do
        msg = "Determining length of the #{String.upcase(axis)} axis"
        FarmbotCore.Celery.SysCalls.log(msg, true)
        FarmbotCore.Celery.SysCalls.calibrate(axis)
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp cs_to_xyz(%{kind: :identifier} = ast, cs_scope) do
    label = ast.args.label
    {:ok, variable} = FarmbotCore.Celery.Compiler.Scope.fetch!(cs_scope, label)
    # Prevent circular refernces.
    # I doubt end users would intentionally do this, so treat
    # it like an error.
    if variable.kind == :identifier, do: raise "Refusing to perform recursion"
    cs_to_xyz(variable, cs_scope)
  end

  defp cs_to_xyz(%{kind: :coordinate} = ast, _) do
    vec_map_to_array(ast.args)
  end

  defp cs_to_xyz(%{kind: :tool, args: args}, _) do
    slot = FarmbotCore.Celery.SysCalls.get_toolslot_for_tool(args.tool_id)
    vec_map_to_array(slot)
  end

  defp cs_to_xyz(%{kind: :point} = ast, _) do
    %{ pointer_type: t, pointer_id: id } = ast.args
    vec_map_to_array(FarmbotCore.Celery.SysCalls.point(t, id))
  end

  defp cs_to_xyz(other, _), do: raise "Unexpected location or offset: #{inspect(other)}"

  defp vec_map_to_array(xyz), do: [ xyz.x, xyz.y, xyz.z ]
end