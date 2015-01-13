require 'rails_helper'
require 'url_utils'

describe UrlUtils do
  describe '.append_protocol' do
    it "append protocol if the URL does not have protocol" do
      expect(UrlUtils.append_protocol('www.example.com')).to eq 'http://www.example.com'
      expect(UrlUtils.append_protocol('www.example.com', 'https')).to eq 'https://www.example.com'
    end

    it "does not append protocol if the URL already has protocol" do
      expect(UrlUtils.append_protocol('http://www.example.com')).to eq 'http://www.example.com'
      expect(UrlUtils.append_protocol('https://www.example.com')).to eq 'https://www.example.com'
    end
  end
end
