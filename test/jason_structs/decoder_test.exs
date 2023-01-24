defmodule Jason.Structs.DecoderTest do
  use ExUnit.Case

  alias Jason.Structs.Decoder

  test "decodes a JSON into a Jason struct" do
    {:ok, json} = File.read("test/fixtures/pesho_encoded.json")

    {:ok, user} = Decoder.decode(json, User)

    assert user == DummyData.user()
  end

  test "decodes a JSON into a Jason struct with namespaced substructs" do
    {:ok, json} = File.read("test/fixtures/billing_account_encoded.json")

    # make sure that the modules are loaded so we don't run into issues with
    # :erlang.binary_to_existing_atom during parse
    Code.ensure_loaded!(Billing.Account)
    Code.ensure_loaded!(Billing.Invoice)
    Code.ensure_loaded!(Billing.InvoiceItem)

    {:ok, account} = Decoder.decode(json, Billing.Account)

    assert account == DummyData.billing_account()
  end

  test "ignores extra and unknown fields in the input when require_existing_atoms is false" do
    {:ok, json} = File.read("test/fixtures/billing_address_encoded_with_unknown_fields.json")

    {:ok, address} = Decoder.decode(json, Address)

    assert address == DummyData.billing_account().billing_address
  end

  test "decodes a JSON into a map if a struct is not passed" do
    {:ok, json} = File.read("test/fixtures/pesho_encoded.json")

    {:ok, user} = Decoder.decode(json)

    assert user == %{
             address: %{
               city: "Yambol",
               country: %{code: "bg", name: "Bulgaria"},
               post_code: "8600",
               street_address_line_one: "jk. Graph Ignatiev",
               street_address_line_two: "bl. 72"
             },
             age: 35,
             children: [
               %{
                 address: %{
                   city: "Yambol",
                   country: %{code: "bg", name: "Bulgaria"},
                   post_code: "8600",
                   street_address_line_one: "jk. Graph Ignatiev",
                   street_address_line_two: "bl. 72"
                 },
                 age: 10,
                 interests: [
                   %{description: "A FPS!", name: "Call Of Duty"},
                   %{description: "Blocks and stuff!", name: "Minecraft"}
                 ],
                 likes_json_structs: false,
                 name: "Ivan Petrov",
                 sex: "male"
               }
             ],
             interests: [
               %{
                 description: "Some people running after a ball and kicking it.",
                 name: "football"
               },
               %{
                 description: "Alcoholic bevarage, very loved on the Balkans.",
                 name: "rakia"
               },
               %{
                 description: "Obicham shopskata salata, mastika ledena da pia.",
                 name: "salata"
               }
             ],
             likes_json_structs: false,
             name: "Petur Petrov",
             sex: "male"
           }
  end

  test "converts the given map into a struct of the given type" do
    {:ok, json} = File.read("test/fixtures/billing_address_encoded.json")
    {:ok, map} = Jason.decode(json)

    address = Decoder.map_to_struct(map, Address)

    assert address == DummyData.billing_account().billing_address
  end

  test "returns a new map with snake_case atoms as keys if no struct module is given" do
    expected = %{
      city: "Hill Valley, CA",
      street_address_line_one: "1640 Riverside Drive",
      post_code: "90999",
      country: %{
        code: "us",
        name: "United States of America"
      }
    }

    {:ok, json} = File.read("test/fixtures/billing_address_encoded.json")
    {:ok, map} = Jason.decode(json)

    address = Decoder.map_to_struct(map, nil)

    assert address == expected
  end
end
