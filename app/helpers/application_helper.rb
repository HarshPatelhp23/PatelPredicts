# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def sort_players_by_role(players)
    players.sort_by { |player| Player.roles[player.role] }
  end

  #IPL
  # def set_background_color(team_name) # rubocop:disable Metrics/CyclomaticComplexity, Naming/AccessorMethodName, Metrics/MethodLength
  #   case team_name.downcase
  #   when 'csk'
  #     'bg-csk'
  #   when 'dc'
  #     'bg-dc'
  #   when 'kkr'
  #     'bg-kkr'
  #   when 'mi'
  #     'bg-mi'
  #   when 'pbks'
  #     'bg-pbks'
  #   when 'rr'
  #     'bg-rr'
  #   when 'rcb'
  #     'bg-rcb'
  #   when 'srh'
  #     'bg-srh'
  #   when 'gt'
  #     'bg-gt'
  #   when 'lsg'
  #     'bg-lsg'
  #   else
  #     ''
  #   end
  # end

  def set_background_color(team_name) # rubocop:disable Metrics/CyclomaticComplexity, Naming/AccessorMethodName, Metrics/MethodLength
    case team_name.downcase
    when 'aus'
      'bg-aus'
    when 'ind'
      'bg-ind'
    when 'sl'
      'bg-sl'
    when 'bang'
      'bg-bang'
    when 'eng'
      'bg-eng'
    when 'afg'
      'bg-afg'
    when 'pak'
      'bg-pak'
    when 'sa'
      'bg-sa'
    when 'wi'
      'bg-wi'
    when 'nz'
      'bg-nz'
    when 'usa'
      'bg-usa'
    when 'ca'
      'bg-ca'
    when 'ire'
      'bg-ire'
    when 'nam'
      'bg-nam'
    when 'nep'
      'bg-nep'
    when 'neth'
      'bg-neth'
    when 'ug'
      'bg-ug'
    when 'omn'
      'bg-omn'
    when 'png'
      'bg-png'
    when 'scot'
      'bg-scot'
    else
      ''
    end
  end
end
