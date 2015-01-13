require 'rails_helper'

describe User do
  subject {create(:user)}
  it { should be }

  # it "should send welcome email upon creation" do
  #   user = create(:user)
  #   last_email.should_not be_blank
  #   last_email.subject.should == I18n.t("user_mailer.welcome.subject")
  #   last_email.to.should == [user.email]
  # end

  it "returns the IDs of the Folders being shared to the User" do
    another_user = create(:user)
    folder = create(:folder, user: another_user)
    sharing = create(:sharing, folder: folder, creator: another_user, user: subject)
    expect(subject.share_folder_ids).to include folder.id
  end

  it "is an admin account if the User is confirmed and the email is included in CONFIG[:user][:admin_emails]" do
    user = create(:user, confirmed_at: nil, email: CONFIG[:user][:admin_emails].first)
    expect(user).to_not be_admin
    user.confirm!
    user.reload
    expect(user).to be_admin
    user = create(:user, confirmed_at: 1.day.ago)
    expect(user).to_not be_admin
  end

  context "omniauth" do
    let(:facebook_auth_hash) {read_fixture_file("facebook_auth_hash.json")}
    let(:twitter_auth_hash) {read_fixture_file("twitter_auth_hash.json")}

    context "finding User for omniauth" do
      it "should apply omniauth for signed in User" do
        expect {
          expect(User.find_for_omniauth(:facebook, facebook_auth_hash, subject)).to eq subject
          expect(subject.accounts.size).to eq 1
        }.to change{Account.count}.by(1)
      end

      it "should find the User by provider and uid" do
        account = create(:account, :user => subject, :provider => 'facebook', :uid => facebook_auth_hash["uid"])
        expect(User.find_for_omniauth(:facebook, facebook_auth_hash, nil)).to eq subject
      end

      it "should find the User by email" do
        subject = create(:user, :email => facebook_auth_hash["info"]["email"])
        expect(User.find_for_omniauth(:facebook, facebook_auth_hash, nil)).to eq subject
      end

      it "should build a user if the user does not exist in the system" do
        # Twitter does not return email.
        user = User.find_for_omniauth(:facebook, twitter_auth_hash, nil)
        expect(user).to be_new_record
      end
    end

    context "building user with omniauth" do
      it "should apply omniauth to the user" do
        session = {'devise.omniauth' => facebook_auth_hash}
        user = User.new_with_session({}, session)
        expect(user.accounts).to_not be_empty
        expect(user.accounts[0].provider).to eq 'facebook'
      end
    end

    context "applying omniauth" do
      context "Facebook" do
        it "sets the email" do
          user = build(:user, email: nil)
          user.apply_omniauth(facebook_auth_hash)
          expect(user.email).to eq facebook_auth_hash["info"]["email"]
        end

        it "sets the full name" do
          user = build(:user, name: nil)
          user.apply_omniauth(facebook_auth_hash)
          expect(user.name).to eq facebook_auth_hash["info"]["name"]
        end

        it "sets the image" do
          user = build(:user, image_url: nil)
          user.apply_omniauth(facebook_auth_hash)
          expect(user.image_url).to eq facebook_auth_hash["info"]["image"]
        end

        it "sets the account information" do
          user = build(:user)
          account = user.apply_omniauth(facebook_auth_hash)
          expect(account.credentials["token"]).to eq facebook_auth_hash["credentials"]["token"]
          expect(account.expires_at).to eq Time.zone.at(facebook_auth_hash["credentials"]["expires_at"])
          expect(account).to be_valid
        end
      end

      context "Twitter" do
        it "sets the full name" do
          user = build(:user, :name => nil)
          user.apply_omniauth(twitter_auth_hash)
          expect(user.name).to eq twitter_auth_hash["info"]["name"]
        end

        it "sets the image" do
          user = build(:user, :image_url => nil)
          user.apply_omniauth(twitter_auth_hash)
          expect(user.image_url).to eq twitter_auth_hash["info"]["image"]
        end

        it "sets the account information" do
          user = build(:user)
          account = user.apply_omniauth(twitter_auth_hash)
          expect(account.credentials["token"]).to eq twitter_auth_hash["credentials"]["token"]
          expect(account).to be_valid
        end
      end

      context "with save" do
        it "should persist user and account" do
          user = build(:user)
          account = user.apply_omniauth!(facebook_auth_hash)
          expect(user).to be_persisted
          expect(account).to be_persisted
          expect(account.user).to eq user
        end
      end

      context "confirmation_period_expires_in" do
        it "returns how many time left before it expires" do
          user = create(:user, confirmed_at: nil)
          user.send_confirmation_instructions
          expect((Time.now + user.confirmation_period_expires_in).to_i).to eq (user.confirmation_sent_at + User.allow_unconfirmed_access_for).to_i
        end
      end

    end
  end

  context "password requirement" do
    let(:user) {build(:user, password: nil, password_confirmation: nil)}

    it "should require password if User has no Accounts" do
      expect(user).to be_password_required
    end

    it "should not require password if User has Account" do
      account = build(:account)
      account.user.password = account.user.password_confirmation = nil
      expect(account.user).to_not be_password_required
    end
  end

  context "has_password" do
    it "should return false for user who does not set up a password" do
      account = build(:account, user: nil)
      user = build(:user, password: nil, password_confirmation: nil)
      user.accounts << account
      user.save!
      expect(user.has_password?).to eq false
    end

    it "should return true for user who set up a password" do
      expect(create(:user).has_password?).to eq true
    end
  end
end
