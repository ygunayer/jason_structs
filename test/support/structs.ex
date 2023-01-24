defmodule Country do
  use Jason.Structs.Struct

  jason_struct do
    field(:code, String.t())
    field(:name, String.t())
  end
end

defmodule Address do
  use Jason.Structs.Struct

  jason_struct require_existing_atoms: false do
    field(:city, String.t())
    field(:street_address_line_one, String.t())
    field(:street_address_line_two, String.t(), enforce: false, excludable: true)
    field(:post_code, String.t(), enforce: false)
    field(:country, Country.t(), enforce: true, excludable: false)
  end
end

defmodule Interest do
  use Jason.Structs.Struct

  jason_struct do
    field(:name, String.t())
    field(:description, String.t())
  end
end

defmodule User do
  use Jason.Structs.Struct

  jason_struct do
    field(:name, String.t())
    field(:age, integer())
    field(:sex, :male | :female, default: :female)
    field(:address, Address.t())
    field(:interests, [Interest.t()], enforce: false, excludable: true, default: [])
    field(:children, [User.t()], enforce: false, excludable: true)
    field(:likes_json_structs, boolean(), enforce: false, default: true)
  end
end

defmodule Billing do
  defmodule InvoiceItem do
    use Jason.Structs.Struct

    jason_struct do
      field(:name, String.t())
      field(:quantity, float())
      field(:unit_price, float())
      field(:subtotal, float())
    end
  end

  defmodule Invoice do
    use Jason.Structs.Struct

    alias Billing.InvoiceItem, as: Item

    jason_struct do
      field(:period, String.t())
      field(:due_date, String.t())
      field(:items, [Item.t()])
      field(:subtotal, float())
    end
  end

  defmodule Account do
    use Jason.Structs.Struct

    alias Billing.Invoice

    jason_struct do
      field(:id, String.t())
      field(:contact_name, String.t())
      field(:contact_email, String.t())
      field(:billing_address, Address.t())
      field(:latest_invoice, Invoice.t())
    end
  end
end
