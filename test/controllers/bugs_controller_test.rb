require "test_helper"

class BugsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      name: "Test User",
      email: "test_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role: :manager
    )
    sign_in @user
  end

  test "should download import failures as CSV" do
    import = BugImport.create!(
      user: @user,
      status: :completed,
      total_count: 5,
      success_count: 3,
      error_count: 2
    )
    
    import.bug_import_errors.create!(row_number: 2, error_message: "Error 1")
    import.bug_import_errors.create!(row_number: 4, error_message: "Error 2")

    get import_bug_result_download_path(import.id)

    assert_response :success
    assert_equal "text/csv", response.headers["Content-Type"]
    assert_match /attachment; filename="import_errors_#{import.id}.csv"/, response.headers["Content-Disposition"]

    csv_data = response.body
    lines = csv_data.strip.split("\n")
    
    assert_equal 3, lines.size
    assert_equal "Row Number,Error Message", lines[0].strip
    assert_equal "2,Error 1", lines[1].strip
    assert_equal "4,Error 2", lines[2].strip
  end
end
