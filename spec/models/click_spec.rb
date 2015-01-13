require 'rails_helper'

RSpec.describe Click, :type => :model do
  let(:link) {create(:link)}
  it 'sets clicked_at before creation' do
    click = Click.create(user: link.user, link: link)
    expect(click.clicked_at).to be
  end
end
