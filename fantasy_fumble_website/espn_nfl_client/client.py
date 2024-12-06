import functools
import logging
import requests

from espn_nfl_client.api_urls import ApiUrls

logger = logging.getLogger(__name__)


class ApiClientException(Exception):
    pass


class InvalidYearApiClientException(ApiClientException):
    pass


class ApiClient:
    """
    Client for the ESPN NFL API.
    """

    def __init__(self, year: int) -> None:
        self.api_urls = ApiUrls(year)
        self.year = year
        self.validate_year()

    @functools.lru_cache(maxsize=128)
    def get_season(self) -> dict:
        response = requests.get(self.api_urls.seasons_url())
        if response.status_code == 404:
            raise InvalidYearApiClientException(
                f"No current season found for year {self.year}"
            )
        return response.json()

    def validate_year(self) -> None:
        try:
            self.get_season()
            self.year_valid = True
        except InvalidYearApiClientException:
            self.year_valid = False
