defprotocol Presentable do
  @fallback_to_any true

  @spec to_type(t()) :: map() | nil
  def to_type(entity)
end
