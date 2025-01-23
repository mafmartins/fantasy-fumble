class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :new, with: -> { redirect_to new_user_url, alert: "Try again later." }
  before_action :set_user, only: %i[ show edit update ]

  # GET /users/1
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to new_session_url, notice: "User was successfully created."
    else
      redirect_to new_user_url, alert: @user.errors.messages
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params_update)
      redirect_to @user, notice: "User was successfully updated."
    else
      redirect_to edit_user_url(@user), alert: @user.errors.messages
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.expect(user: [ :username, :email_address, :password, :password_confirmation ])
    end

    def user_params_update
      params.require(:user).permit(:username, :email_address)
    end
end
