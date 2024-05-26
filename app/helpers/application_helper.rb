# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def sort_players_by_role(players)
    players.sort_by { |player| Player.roles[player.role] }
  end

  def set_background_color(team_name) # rubocop:disable Metrics/CyclomaticComplexity, Naming/AccessorMethodName, Metrics/MethodLength
    case team_name.downcase
    when 'csk'
      'bg-csk'
    when 'dc'
      'bg-dc'
    when 'kkr'
      'bg-kkr'
    when 'mi'
      'bg-mi'
    when 'pbks'
      'bg-pbks'
    when 'rr'
      'bg-rr'
    when 'rcb'
      'bg-rcb'
    when 'srh'
      'bg-srh'
    when 'gt'
      'bg-gt'
    when 'lsg'
      'bg-lsg'
    else
      ''
    end
  end
end
