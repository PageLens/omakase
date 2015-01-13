json.array!(@feedbacks) do |feedback|
  json.extract! feedback, :id, :email, :subject, :description, :note
  json.url feedback_url(feedback, format: :json)
end
