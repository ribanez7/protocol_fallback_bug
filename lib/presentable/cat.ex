defimpl Presentable, for: Models.Cat do
  def to_type(%Models.Cat{name: name}), do: %{kind: "cat", name: name}
end
