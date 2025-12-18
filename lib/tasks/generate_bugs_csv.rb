require "csv"
require "faker"

Faker::Config.locale = "en"

file_path = Rails.root.join("tmp/test_bugs_large.csv")

project_ids = Project.pluck(:id)

# Allowed assignees
allowed_assignees = [ 1, 2, 4, 5, 6, 7, 9, 10, 11 ]

CSV.open(file_path, "wb") do |csv|
  csv << [ "title", "description", "due_date", "project_id", "priority", "severity", "status", "bug_type", "bug_assignees" ]

  150_000.times do |i|
    project_id = project_ids.sample

    # Use different words with Faker methods available in 3.5.3
    title = "#{Faker::App.name} #{Faker::Job.key_skill} #{Faker::Hacker.abbreviation} error #{i}" # i ensures uniqueness
    description = "#{Faker::Company.catch_phrase}. #{Faker::Hacker.ingverb} #{Faker::ProgrammingLanguage.name} code causes issue."

    due_date = Faker::Date.forward(days: 60)
    priority = %w[low medium high].sample
    severity = %w[minor major critical].sample
    status = %w[open closed reopened].sample
    bug_type = %w[ui backend performance security].sample

    # Select 1–3 assignees from allowed list
    assignees = allowed_assignees.sample(rand(1..3)).join(",")

    csv << [ title, description, due_date, project_id, priority, severity, status, bug_type, assignees ]
  end
end

puts "CSV generated in English at #{file_path}"
