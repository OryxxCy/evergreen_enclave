class PlantsController < ApplicationController
  def index
    # @plants = Plant.all
    @plants = Plant.page(params[:page]).per(12)
  end

  def show
    @plant = Plant.find(params[:id])
  end

  def search
    search_term = "%#{params[:keywords]}%"
    if params[:type].present?
      @plants = Plant.joins(:plant_type).where("plants.name LIKE ? AND plant_types.name = ?", search_term, params[:type])
    else
      @plants = Plant.where("name LIKE ?", search_term)
    end
  end
end
