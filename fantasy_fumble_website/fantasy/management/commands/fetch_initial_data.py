import logging

from django.core.management.base import BaseCommand, CommandError
from django.db.utils import IntegrityError
from django.utils.timezone import now

from fantasy.models import (
    Athlete,
    Group,
    League,
    Season,
    SeasonType,
    Team,
    Week,
)
from espn_nfl_client.client import ApiClient

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = (
        "Initialize the database with the current NFL season data "
        "(teams, players, etc.)"
    )

    def create_league(self) -> League:
        league, _ = League.objects.get_or_create(
            slug="nfl",
            name="National Football League",
            abbreviation="NFL",
            is_active=True,
        )
        return league

    def create_seasons(
        self, api_client: ApiClient, league: League, year: int
    ) -> list[Season]:
        response = api_client.get_season()
        season_types_to_create = []
        seasons_to_create = []
        for season_type in response["types"]["items"]:
            season_types_to_create.append(
                SeasonType(
                    name=season_type["name"],
                    abbreviation=season_type["abbreviation"],
                    type=season_type["type"],
                )
            )

        created_season_types = SeasonType.objects.bulk_create(
            season_types_to_create
        )
        for season_type in created_season_types:
            season = response["types"]["items"][0]
            seasons_to_create.append(
                Season(
                    year=year,
                    start_date=season["startDate"],
                    end_date=season["endDate"],
                    league=league,
                    type=season_type,
                )
            )
        created_seasons = Season.objects.bulk_create(seasons_to_create)
        return created_seasons

    def create_groups(self, league: League) -> None:
        pass

    def handle(self, *args, **options):
        try:
            year = now().year
            api_client = ApiClient(year)
            if not api_client.year_valid:
                logger.warning(
                    f"No season found for year {year}, trying previous year"
                )
                api_client = ApiClient(year - 1)
                if not api_client.year_valid:
                    raise CommandError(f"No season found for year {year - 1}")
                year = year - 1

            # Create the NFL league
            league = self.create_league()

            # Create the NFL season
            seasons = self.create_seasons(api_client, league, year)
            current_season = next(
                season for season in seasons if season.is_active()
            )
        except IntegrityError:
            msg = (
                "The database is not empty. This command should only be run "
                "on an empty database."
            )
            logger.error(msg)
            raise CommandError(msg)
