defimpl Presentable, for: Models.Dog do
  def to_type(%Models.Dog{name: name}), do: %{kind: "dog", name: name}
end
