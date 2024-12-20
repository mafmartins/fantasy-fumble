# Generated by Django 5.1.3 on 2024-12-06 22:42

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="League",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("slug", models.CharField(max_length=50, unique=True)),
                ("name", models.CharField(max_length=50, unique=True)),
                ("abbreviation", models.CharField(max_length=3, unique=True)),
                ("is_active", models.BooleanField()),
            ],
        ),
        migrations.CreateModel(
            name="Position",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("abbreviation", models.CharField(max_length=3)),
                ("name", models.CharField(max_length=50)),
                ("is_offense", models.BooleanField()),
                ("is_defense", models.BooleanField()),
                ("is_special_teams", models.BooleanField()),
                ("is_active", models.BooleanField()),
            ],
        ),
        migrations.CreateModel(
            name="SeasonType",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("name", models.CharField(max_length=50, unique=True)),
                ("abbreviation", models.CharField(max_length=5, unique=True)),
                ("type", models.IntegerField()),
            ],
        ),
        migrations.CreateModel(
            name="Group",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("espn_id", models.IntegerField()),
                ("name", models.CharField(max_length=50, unique=True)),
                ("abbreviation", models.CharField(max_length=3)),
                ("is_conference", models.BooleanField()),
                ("logo", models.ImageField(null=True, upload_to="logos")),
                ("is_active", models.BooleanField()),
                (
                    "parent_group",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.PROTECT,
                        to="fantasy.group",
                    ),
                ),
                (
                    "league",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE, to="fantasy.league"
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="Season",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("year", models.IntegerField()),
                ("start_date", models.DateTimeField()),
                ("end_date", models.DateTimeField()),
                (
                    "league",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE, to="fantasy.league"
                    ),
                ),
                (
                    "type",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        to="fantasy.seasontype",
                    ),
                ),
            ],
            options={
                "unique_together": {("year", "type", "league")},
            },
        ),
        migrations.CreateModel(
            name="Team",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("espn_id", models.IntegerField()),
                ("slug", models.CharField(max_length=50)),
                ("abbreviation", models.CharField(max_length=3)),
                ("display_name", models.CharField(max_length=50)),
                ("short_display_name", models.CharField(max_length=50)),
                ("name", models.CharField(max_length=50)),
                ("nickname", models.CharField(max_length=50)),
                ("location", models.CharField(max_length=50)),
                ("color", models.CharField(max_length=6)),
                ("alternate_color", models.CharField(max_length=6)),
                ("logo", models.ImageField(null=True, upload_to="logos")),
                ("is_active", models.BooleanField()),
                (
                    "group",
                    models.ForeignKey(
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        to="fantasy.group",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="Athlete",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("espn_id", models.IntegerField()),
                ("first_name", models.CharField(max_length=50)),
                ("last_name", models.CharField(max_length=50)),
                ("full_name", models.CharField(max_length=50)),
                ("display_name", models.CharField(max_length=50)),
                ("short_name", models.CharField(max_length=50)),
                ("weight", models.IntegerField()),
                ("height", models.IntegerField()),
                ("age", models.IntegerField()),
                ("date_of_birth", models.DateField()),
                ("experience_years", models.IntegerField()),
                ("jersey", models.IntegerField()),
                ("college_abbreviation", models.CharField(max_length=3)),
                ("headshot", models.ImageField(upload_to="headshots")),
                ("is_active", models.BooleanField()),
                (
                    "position",
                    models.ForeignKey(
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        to="fantasy.position",
                    ),
                ),
                (
                    "team",
                    models.ForeignKey(
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        to="fantasy.team",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="Week",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("espn_id", models.IntegerField()),
                ("number", models.IntegerField()),
                (
                    "season",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE, to="fantasy.season"
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="Game",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("espn_id", models.IntegerField()),
                ("start_date", models.DateTimeField()),
                ("home_team_score", models.IntegerField()),
                ("away_team_score", models.IntegerField()),
                ("home_team_winner", models.BooleanField()),
                ("neutral_site", models.BooleanField()),
                ("is_active", models.BooleanField()),
                (
                    "away_team",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="games_away_team",
                        to="fantasy.team",
                    ),
                ),
                (
                    "home_team",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="games_home_team",
                        to="fantasy.team",
                    ),
                ),
                (
                    "week",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE, to="fantasy.week"
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="AthletesGamesStats",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("passing_touchdowns", models.IntegerField(default=0)),
                ("receiving_touchdowns", models.IntegerField(default=0)),
                ("rushing_touchdowns", models.IntegerField(default=0)),
                ("offensive_fumbles_touchdowns", models.IntegerField(default=0)),
                ("passing_touchdowns_40_plus", models.IntegerField(default=0)),
                ("receiving_touchdowns_40_plus", models.IntegerField(default=0)),
                ("rushing_touchdowns_40_plus", models.IntegerField(default=0)),
                ("passing_yards", models.IntegerField(default=0)),
                ("rushing_yards", models.IntegerField(default=0)),
                ("receiving_yards", models.IntegerField(default=0)),
                ("interceptions_thrown", models.IntegerField(default=0)),
                ("fumbles_lost", models.IntegerField(default=0)),
                ("two_point_rush_conversions", models.IntegerField(default=0)),
                ("two_point_pass_conversions", models.IntegerField(default=0)),
                ("two_point_receive_conversions", models.IntegerField(default=0)),
                ("field_goals_made_1_39", models.IntegerField(default=0)),
                ("field_goals_made_40_49", models.IntegerField(default=0)),
                ("field_goals_made_50_plus", models.IntegerField(default=0)),
                ("field_goals_missed_0_39", models.IntegerField(default=0)),
                ("field_goals_missed_40_49", models.IntegerField(default=0)),
                ("extra_points_made", models.IntegerField(default=0)),
                ("defensive_touchdowns", models.IntegerField(default=0)),
                ("defensive_interceptions", models.IntegerField(default=0)),
                ("fumble_recoveries", models.IntegerField(default=0)),
                ("blocked_kicks", models.IntegerField(default=0)),
                ("safeties", models.IntegerField(default=0)),
                ("sacks", models.IntegerField(default=0)),
                (
                    "athlete",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        to="fantasy.athlete",
                    ),
                ),
                (
                    "game",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE, to="fantasy.game"
                    ),
                ),
            ],
            options={
                "unique_together": {("athlete", "game")},
            },
        ),
    ]
