class HttpResponse
  def initialize(response = nil)
    @response = response
  end

  def body
    @response ? @response : default_response
  end

  def code
    default_code
  end

  private
    def default_response
      {}
    end

    def default_code
      "200"
    end
end

class HttpResponseOkMock < HttpResponse
  private
    def default_code
      "200"
    end
end

class HttpResponseNotFoundMock < HttpResponse
  private
    def default_response
      {
        "error" => {
          "message" => "application error",
          "code" => 404
        }
      }.to_json
    end

    def default_code
      "404"
    end
end

module EspnNflClientHttpMock
  def self.load_responses
    file_path = Rails.root.join("test/fixtures/files/espn_responses.json")
    JSON.load_file(file_path)
  end

  def self.mock_response(url)
    responses = load_responses
    case url
    when /groups\/\d\d\/teams/
      responses["groups/int/teams"].to_json
    when /groups\/\d\/children/
      responses["groups/parent_int/children"].to_json
    when /groups\/\d\d/
      responses["groups/child_int"].to_json
    when /groups\/\d/
      responses["groups/parent_int"].to_json
    when /groups/
      responses["groups"].to_json
    when /teams\/\d*\/athletes\?limit\=1000\&page\=1/
      responses["teams/int/athletes?page=1"].to_json
    when /teams\/\d*\/athletes\?limit\=1000\&page\=2/
      responses["teams/int/athletes?page=2"].to_json
    when /teams\/\d/
      responses["teams/int"].to_json
    when /athletes\/1/
      responses["athletes/1"].to_json
    when /athletes\/2/
      responses["athletes/2"].to_json
    when /positions\/1/
      responses["positions/1"].to_json
    when /positions\/70/
      responses["positions/70"].to_json
    when /positions/
      responses["positions"].to_json
    else
      {}.to_json
    end
  end

  def self.get_response_ok(url)
    @response = mock_response(url)
    HttpResponseOkMock.new(@response)
  end

  def self.get_response_not_found(url)
    HttpResponseNotFoundMock.new
  end
end
