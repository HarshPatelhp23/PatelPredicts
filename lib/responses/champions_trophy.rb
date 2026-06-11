module Responses
  class ChampionsTrophy
    CT_2025 = {
      "typeMatches" => [
        {
          "matchType" => "International",
          "seriesMatches" => [
            {
              "seriesAdWrapper" => {
                "seriesId" => 9325,
                "seriesName" => "ICC Champions Trophy, 2025",
                "matches" => [
                  {
                    "matchInfo" => {
                      "matchId" => 112395,
                      "seriesId" => 9325,
                      "seriesName" => "ICC Champions Trophy, 2025",
                      "matchDesc" => "1st Match, Group A",
                      "matchFormat" => "ODI",
                      "startDate" => "1739955600000",
                      "endDate" => "1739984400000",
                      "state" => "Complete",
                      "status" => "New Zealand won by 60 runs",
                      "team1" => {"teamId" => 13, "teamName" => "New Zealand", "teamSName" => "NZ", "imageId" => 172128},
                      "team2" => {"teamId" => 3, "teamName" => "Pakistan", "teamSName" => "PAK", "imageId" => 591986},
                      "venueInfo" => {
                        "id" => 24,
                        "ground" => "National Stadium",
                        "city" => "Karachi",
                        "timezone" => "+05:00",
                        "latitude" => "24.892373",
                        "longitude" => "67.086411"
                      },
                      "currBatTeamId" => 13,
                      "seriesStartDt" => "1739923200000",
                      "seriesEndDt" => "1741651200000",
                      "isTimeAnnounced" => true,
                      "stateTitle" => "Complete",
                      "isFantasyEnabled" => true
                    },
                    "matchScore" => {
                      "team1Score" => {"inngs1" => {"inningsId" => 1, "runs" => 320, "wickets" => 5, "overs" => 49.6}},
                      "team2Score" => {"inngs1" => {"inningsId" => 2, "runs" => 260, "wickets" => 10, "overs" => 47.2}}
                    }
                  }
                ]
              }
            }
          ]
        }
      ]
    }
    
    def self.champions_trophy_2025
      CT_2025
    end
  end
end