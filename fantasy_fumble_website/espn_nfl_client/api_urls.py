from espn_nfl_client.constants import EspnSeasonType
from espn_nfl_client.settings import (
    SITE_API_BASE_URL,
    SPORTS_CORE_API_BASE_URL,
)


class ApiUrls:
    def __init__(self, year: int) -> None:
        self.site_api_base_url = SITE_API_BASE_URL
        self.sports_core_api_base_url = SPORTS_CORE_API_BASE_URL
        self.year = year

    def seasons_url(self) -> str:
        return self.sports_core_api_base_url + f"seasons/{self.year}"

    def groups_url(self, season_type: EspnSeasonType) -> str:
        return (
            self.sports_core_api_base_url
            + f"seasons/{self.year}/types/{season_type}/groups"
        )

    def group_url(
        self, season_type: EspnSeasonType, espn_group_id: str
    ) -> str:
        return (
            self.sports_core_api_base_url
            + f"seasons/{self.year}/types/{season_type}/groups/{espn_group_id}"
        )

    def teams_list_url(self) -> str:
        return self.site_api_base_url + "teams"

    def athletes_by_team_url(self, espn_team_id: str) -> str:
        return self.sports_core_api_base_url + f"teams/{espn_team_id}/roster"

    def season_url(self, season_type: EspnSeasonType) -> str:
        return (
            self.site_api_base_url + f"seasons/{self.year}/types/{season_type}"
        )
