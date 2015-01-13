require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the FoldersHelper. For example:
#
# describe FoldersHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe FoldersHelper, :type => :helper do
  describe '#modal_form_title' do
    it 'returns the name of the Folder if folder has been persisited' do
      folder = create(:folder)
      expect(helper.modal_form_title(folder)).to eq(folder.name)
    end

    it 'returns new folder if folder has not been persisted' do
      folder = build(:folder)
      expect(helper.modal_form_title(folder)).to eq(t('folders.modal_form.new_folder'))
    end
  end
end
