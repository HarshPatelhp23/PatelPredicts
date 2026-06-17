require "test_helper"

class MatchMailerTest < ActionMailer::TestCase
  test "match_summary" do
    mail = MatchMailer.match_summary
    assert_equal "Match summary", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
