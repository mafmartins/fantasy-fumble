class HttpResponseMock
  def initialize(response)
    @response = response
  end
  def body
    @response
  end

  def code
    "200"
  end
end

module EspnNflClientHttpMock
  def self.mock_response(url)
    case url
    when /groups\/8\/children/
      {
        "count" => 4,
        "pageIndex" => 1,
        "pageSize" => 25,
        "pageCount" => 1,
        "items" => [
          {
            "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/12?lang=en&region=us"
          }
        ]
      }.to_json
    when /groups\/8/
      {
        "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/8?lang=en&region=us",
        "uid" => "s:20~l:28~g:8",
        "id" => "8",
        "name" => "American Football Conference",
        "abbreviation" => "AFC",
        "season" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024?lang=en&region=us"
        },
        "children" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/8/children?lang=en&region=us"
        },
        "parent" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/9?lang=en&region=us"
        },
        "standings" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/8/standings?lang=en&region=us"
        },
        "isConference" => true,
        "slug" => "american-football-conference",
        "teams" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/8/teams?lang=en&region=us"
        }
      }.to_json
    when /groups\/12/
      {
        "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/12?lang=en&region=us",
        "uid" => "s:20~l:28~g:12",
        "id" => "12",
        "name" => "AFC North",
        "abbreviation" => "NORTH",
        "season" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024?lang=en&region=us"
        },
        "parent" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/8?lang=en&region=us"
        },
        "standings" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/12/standings?lang=en&region=us"
        },
        "isConference" => false,
        "slug" => "afc-north",
        "teams" => {
          "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/12/teams?lang=en&region=us"
        }
      }.to_json
    when /groups/
      {
        "count" => 2,
        "pageIndex" => 1,
        "pageSize" => 25,
        "pageCount" => 1,
        "items" => [
          {
            "$ref" => "http://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2024/types/2/groups/8?lang=en&region=us"
          }
        ]
      }.to_json
    else
      {}.to_json
    end
  end

  def self.get_response(url)
    @response = mock_response(url)
    HttpResponseMock.new(@response)
  end
end
