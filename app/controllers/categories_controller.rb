class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show edit update destroy]
  def index
    @categories = Category.all
  end

  def show
  end

  def new
    @category = Category.new
    render :form
  end

  def create

    @category = Category.new(category_params)
    @category.user = @user

    if @category.save
      redirect_to category_path(@category)
      flash[:alert] = "Categoria criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
     render :form
  end

  def update
    @category = Category.new(category_params)
    @category.user = @user
    if @category.save
      redirect_to category_path(@category)
      flash[:alert] = "Categoria alterada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    flash[:alert] = "Categoria excluída com sucesso."

    redirect_to categorys_path()
  end

  private

  # Permits category parameters
  def category_params
    params.require(:category).permit( :name, :icon, :is_income, :color, :date, :user_id)
  end

  def set_category
    @category = Category.find(params[:id])
  end
end
