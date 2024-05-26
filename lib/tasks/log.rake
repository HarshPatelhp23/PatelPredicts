# frozen_string_literal: true

namespace :log do
  desc 'TODO'
  task clear_logfile: :environment do
    prodcution_log_file = Rails.root.join('log/production.log')
    if File.exist?(prodcution_log_file)
      File.truncate(prodcution_log_file, 0)
      puts 'Production log file cleared successfully.'
    else
      puts 'Production log file does not exist.'
    end
    development_log_file = Rails.root.join('log/development.log')
    if File.exist?(development_log_file)
      File.truncate(development_log_file, 0)
      puts 'Development log file cleared successfully.'
    else
      puts 'Development log file does not exist.'
    end
  end
end
