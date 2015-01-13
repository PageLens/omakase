require 'rails_helper'

RSpec.describe HomeHelper, :type => :helper do
  describe '#combined_javascript_url' do
    it "combines JavaScript files" do
      expect(helper.combined_javascript_url("application")).to match /\/assets\/application.js/
    end
  end
end
