// app/assets/javascripts/active_admin_custom.js

$(document).ready(function() {
  // Target the team dropdown and player dropdown by their IDs
  var $teamDropdown = $('#match_team_id');
  var $playerDropdown = $('#match_player_id');
  var $matchNameField = $('#match_match_name');

  // Initial state: Disable the player dropdown
  $playerDropdown.prop('disabled', true);
  // Function to update the player dropdown options based on team and match name
  function updatePlayerDropdown(teamId, matchName) {
    $.ajax({
      url: '/players_by_team',
      type: 'GET',
      data: { team_id: teamId, match_name: matchName },
      dataType: 'json',
      success: function(data) {
        $playerDropdown.empty();
        $playerDropdown.append($('<option>', {
          value: '',
          text: 'Select a player',
        }));
        $.each(data.options, function(index, option) {
          $playerDropdown.append($('<option>', {
            value: option[1],
            text: option[0],
          }));
        });
        $playerDropdown.prop('disabled', false);
      },
      error: function() {
        console.log('AJAX request failed');
      }
    });
  }

  // Listen for changes in the team dropdown and match name field
  $teamDropdown.on('change', function() {
    var selectedTeamId = $(this).val();
    var enteredMatchName = $matchNameField.val();

    if (selectedTeamId && enteredMatchName) {
      updatePlayerDropdown(selectedTeamId, enteredMatchName);
    } else {
      $playerDropdown.prop('disabled', true);
      $playerDropdown.empty();
    }
  });

  $matchNameField.on('input', function() {
    var selectedTeamId = $teamDropdown.val();
    var enteredMatchName = $(this).val();

    if (selectedTeamId && enteredMatchName) {
      updatePlayerDropdown(selectedTeamId, enteredMatchName);
    } else {
      $playerDropdown.prop('disabled', true);
      $playerDropdown.empty();
    }
  });
});
