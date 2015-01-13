require 'rails_helper'

RSpec.describe ApplicationHelper, :type => :helper do
  describe '#friendly_time_tag' do
    context "with time" do
      it "uses distance of time in words to now when the time is less than long_format_distance" do
        [1.minutes.ago, 1.day.ago, 1.week.ago, 3.week.ago].each do |t|
          expect(helper.friendly_time_tag(t, :long_format_distance => 1.month)).to match /#{I18n.t('global.time_ago', :time => distance_of_time_in_words_to_now(t))}/
        end
      end

      # it "formats the date if the time is older than long_format_distance" do
      #   [1.month.ago, 3.months.ago, 1.year.ago, 3.years.ago].each do |t|
      #     expect(helper.friendly_time_tag(t, :long_format_distance => 1.month)).to match /#{I18n.l(t.to_date, :format => :long)}/
      #   end
      # end
    end

    context "with string" do
      it "uses distance of time in words to now when the time is less than long_format_distance" do
        [1.minutes.ago, 1.day.ago, 1.week.ago, 3.week.ago].each do |t|
          expect(helper.friendly_time_tag(t.iso8601, :long_format_distance => 1.month)).to match /#{I18n.t('global.time_ago', :time => distance_of_time_in_words_to_now(t))}/
        end
      end

      it "formats the date if the time is older than long_format_distance" do
        [1.month.ago, 3.months.ago, 1.year.ago, 3.years.ago].each do |t|
          expect(helper.friendly_time_tag(t.iso8601, :long_format_distance => 1.month)).to match /#{I18n.l(t.to_date, :format => :long)}/
        end
      end
    end
  end
end
