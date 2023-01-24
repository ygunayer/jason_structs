defmodule Jason.Structs.Decoder do
  @moduledoc """
  A JSON Decoder that can decode a JSON to a `Jason.Structs` struct, if its module is provided.

  The decoding process is recursive and if the strcut has fields that are `Jason.Structs` structs,
  they are also decoded.

  If the struct has fields, that are normal structs they'll be decoded as maps.
  """

  @doc """
  Decodes the passed iodata JSON to a struct of the given `struct_module` type.

  If the `struct_module` is passed as `nil`, the result is just a map.
  """
  @spec decode(json :: iodata(), struct_module :: module() | nil) ::
          {:ok, map()} | {:error, term()}
  def decode(json, struct_module \\ nil) do
    case Jason.decode(json) do
      {:ok, map} ->
        result = map_to_struct(map, struct_module)

        {:ok, result}

      {:error, _} = error ->
        error
    end
  end

  def map_to_struct(map, nil), do: keys_to_snake_style_atoms(map, true)

  def map_to_struct(map, struct_module) do
    require_existing_atoms =
      if Kernel.function_exported?(struct_module, :jason_struct_options, 0) do
        Keyword.get(struct_module.jason_struct_options(), :require_existing_atoms, true)
      else
        false
      end

    map
    |> keys_to_snake_style_atoms(require_existing_atoms)
    |> to_struct(struct_module)
  end

  defp keys_to_snake_style_atoms(map, require_existing_atoms) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      new_key = key_to_snake_style_atom(key, require_existing_atoms)
      new_value = keys_to_snake_style_atoms(value, require_existing_atoms)

      Map.put_new(acc, new_key, new_value)
    end)
  end

  defp keys_to_snake_style_atoms(list, require_existing_atoms) when is_list(list) do
    Enum.map(list, fn entry -> keys_to_snake_style_atoms(entry, require_existing_atoms) end)
  end

  defp keys_to_snake_style_atoms(value, _), do: value

  defp key_to_snake_style_atom(key, require_existing_atoms) when is_atom(key),
    do: key |> Atom.to_string() |> key_to_snake_style_atom(require_existing_atoms)

  defp key_to_snake_style_atom(key, true),
    do: key |> Macro.underscore() |> String.to_existing_atom()

  defp key_to_snake_style_atom(key, false), do: key |> Macro.underscore() |> String.to_atom()

  defp to_struct(value, nil), do: value

  defp to_struct(map, struct_module) when is_map(map) and is_atom(struct_module) do
    updated_map =
      Enum.reduce(map, %{}, fn {key, value}, acc ->
        struct_m = Map.get(struct_module.sub_structs(), key)
        type_info = Map.get(struct_module.type_data(), key)

        Map.put_new(acc, key, to_struct(value, struct_m || type_info))
      end)

    struct(struct_module, updated_map)
  end

  defp to_struct(list, struct_module) when is_list(list) and is_atom(struct_module) do
    Enum.map(list, fn entry -> to_struct(entry, struct_module) end)
  end

  # TODO validation, there is some problem in TypedStruct with sum of more than 3 values.
  defp to_struct(value, {:enum, values}) do
    values = Enum.map(values, &Atom.to_string/1)

    if value in values do
      String.to_existing_atom(value)
    end
  end

  defp to_struct(value, _), do: value
end
