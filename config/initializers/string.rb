class String
  def encode_from_charset!(encoding)
    encode!('UTF-8', encoding.try(:upcase) || nil, invalid: :replace, undef: :replace, replace: '?')
  end
end
