from django.db import models
from django.utils.timezone import now


class League(models.Model):
    espn_id = models.IntegerField()
    slug = models.CharField(max_length=50)
    name = models.CharField(max_length=50)
    abbreviation = models.CharField(max_length=3)
    is_active = models.BooleanField()

    def __str__(self):
        return self.name


class Group(models.Model):
    espn_id = models.IntegerField()
    name = models.CharField(max_length=50)
    abbreviation = models.CharField(max_length=3)
    is_conference = models.BooleanField()
    logo = models.ImageField(upload_to="logos", null=True)
    is_active = models.BooleanField()

    parent_group = models.ForeignKey(
        "Group", on_delete=models.PROTECT, null=True, blank=True
    )
    league = models.ForeignKey("League", on_delete=models.CASCADE)

    def __str__(self):
        return self.name


class Season(models.Model):
    year = models.IntegerField()
    start_date = models.DateField()
    end_date = models.DateField()
    type = models.CharField(
        max_length=50,
        choices=[
            ("pre", "Preseason"),
            ("reg", "Regular"),
            ("post", "Postseason"),
        ],
    )

    league = models.ForeignKey("League", on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.league.name} {self.year}"

    def is_active(self):
        return self.start_date <= now().date() <= self.end_date


class Week(models.Model):
    espn_id = models.IntegerField()
    number = models.IntegerField()

    season = models.ForeignKey("Season", on_delete=models.CASCADE)

    def __str__(self):
        return f"Week {self.number} - {self.season}"


class Game(models.Model):
    espn_id = models.IntegerField()
    start_date = models.DateTimeField()
    home_team_score = models.IntegerField()
    away_team_score = models.IntegerField()
    home_team_winner = models.BooleanField()
    neutral_site = models.BooleanField()
    is_active = models.BooleanField()

    week = models.ForeignKey("Week", on_delete=models.CASCADE)
    home_team = models.ForeignKey(
        "Team", on_delete=models.CASCADE, related_name="games_home_team"
    )
    away_team = models.ForeignKey(
        "Team", on_delete=models.CASCADE, related_name="games_away_team"
    )

    def __str__(self):
        return f"{self.away_team} @ {self.home_team}"


class PlayerGameStats(models.Model):
    # Offensive stats
    passing_touchdowns = models.IntegerField(
        default=0
    )  # passing.passingTouchdowns
    receiving_touchdowns = models.IntegerField(
        default=0
    )  # receiving.receivingTouchdowns
    rushing_touchdowns = models.IntegerField(
        default=0
    )  # rushing.rushingTouchdowns
    offensive_fumbles_touchdowns = models.IntegerField(
        default=0
    )  # general.offensiveFumblesTouchdowns
    passing_touchdowns_40_plus = models.IntegerField(
        default=0
    )  # passing.passingTouchdownsOf40to49Yds
    # + passing.passingTouchdownsOf50PlusYds
    receiving_touchdowns_40_plus = models.IntegerField(
        default=0
    )  # receiving.receivingTouchdownsOf40to49Yds
    # + receiving.receivingTouchdownsOf50PlusYds
    rushing_touchdowns_40_plus = models.IntegerField(
        default=0
    )  # rushing.rushingTouchdownsOf40to49Yds
    # + rushing.rushingTouchdownsOf50PlusYds
    passing_yards = models.IntegerField(default=0)  # passing.passingYards
    rushing_yards = models.IntegerField(default=0)  # rushing.rushingYards
    receiving_yards = models.IntegerField(
        default=0
    )  # receiving.receivingYards
    interceptions_thrown = models.IntegerField(
        default=0
    )  # passing.interceptions
    fumbles_lost = models.IntegerField(default=0)  # general.fumblesLost
    two_point_rush_conversions = models.IntegerField(
        default=0
    )  # rushing.twoPtRush
    two_point_pass_conversions = models.IntegerField(
        default=0
    )  # passing.twoPtPass
    two_point_receive_conversions = models.IntegerField(
        default=0
    )  # receiving.twoPtReception

    # Kicking stats
    field_goals_made_1_39 = models.IntegerField(
        default=0
    )  # kicking.fieldGoalsMade1_19 + kicking.fieldGoalsMade20_29
    # + kicking.fieldGoalsMade30_39
    field_goals_made_40_49 = models.IntegerField(
        default=0
    )  # kicking.fieldGoalsMade40_49
    field_goals_made_50_plus = models.IntegerField(
        default=0
    )  # kicking.fieldGoalsMade50
    field_goals_missed_0_39 = models.IntegerField(
        default=0
    )  # kicking.fieldGoalAttempts1_19 - kicking.fieldGoalsMade1_19
    # + kicking.fieldGoalAttempts20_29 - kicking.fieldGoalsMade20_29
    # + kicking.fieldGoalAttempts30_39 - kicking.fieldGoalsMade30_39
    field_goals_missed_40_49 = models.IntegerField(
        default=0
    )  # kicking.fieldGoalAttempts40_49 - kicking.fieldGoalsMade40_49
    extra_points_made = models.IntegerField(
        default=0
    )  # kicking.extraPointsMade

    # Defensive/Special teams stats
    defensive_touchdowns = models.IntegerField(
        default=0
    )  # defensive.defensiveTouchdowns
    defensive_interceptions = models.IntegerField(
        default=0
    )  # defensiveInterceptions.interceptions
    fumble_recoveries = models.IntegerField(
        default=0
    )  # general.fumblesRecovered
    blocked_kicks = models.IntegerField(default=0)  # defensive.kicksBlocked
    safeties = models.IntegerField(default=0)  # defensive.safeties
    sacks = models.IntegerField(
        default=0
    )  # defensive.sacksAssisted + defensive.sacksUnassisted

    player = models.ForeignKey("Player", on_delete=models.CASCADE)
    game = models.ForeignKey("Game", on_delete=models.CASCADE)

    class Meta:
        unique_together = ("player", "game")
        indexes = [
            models.Index(fields=["player", "game"]),
        ]


class Team(models.Model):
    espn_id = models.IntegerField()
    slug = models.CharField(max_length=50)
    abbreviation = models.CharField(max_length=3)
    display_name = models.CharField(max_length=50)
    short_display_name = models.CharField(max_length=50)
    name = models.CharField(max_length=50)
    nickname = models.CharField(max_length=50)
    location = models.CharField(max_length=50)
    color = models.CharField(max_length=6)
    alternate_color = models.CharField(max_length=6)
    logo = models.ImageField(upload_to="logos", null=True)
    is_active = models.BooleanField()

    group = models.ForeignKey("Group", on_delete=models.SET_NULL, null=True)

    def __str__(self):
        return self.display_name


class Player(models.Model):
    espn_id = models.IntegerField()
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    full_name = models.CharField(max_length=50)
    display_name = models.CharField(max_length=50)
    short_name = models.CharField(max_length=50)
    weight = models.IntegerField()
    height = models.IntegerField()
    age = models.IntegerField()
    date_of_birth = models.DateField()
    experience_years = models.IntegerField()
    jersey = models.IntegerField()
    college_abbreviation = models.CharField(max_length=3)
    headshot = models.ImageField(upload_to="headshots")
    is_active = models.BooleanField()

    position = models.ForeignKey(
        "Position", on_delete=models.SET_NULL, null=True
    )
    team = models.ForeignKey("Team", on_delete=models.SET_NULL, null=True)

    def __str__(self):
        return self.full_name


class Position(models.Model):
    abbreviation = models.CharField(max_length=3)
    name = models.CharField(max_length=50)
    is_offense = models.BooleanField()
    is_defense = models.BooleanField()
    is_special_teams = models.BooleanField()
    is_active = models.BooleanField()

    def __str__(self):
        return self.name
