class CartController < ApplicationController
  def create
    product_id = params[:id]
    quantity = params[:quantity].to_i
    plant = Plant.find_by(id: product_id)
    if session[:shopping_cart].key?(product_id)
      if params[:source].present?
        session[:shopping_cart][product_id] = quantity
        redirect_to cart_index_path
      else
        session[:shopping_cart][product_id] += quantity
        # flash[:notice] = "#{quantity} #{plant.name} added to cart."
        redirect_to plant_path(product_id)
      end
    else
      session[:shopping_cart][product_id] = quantity
    end

    plant = Plant.find(product_id)
    flash[:notice] = "#{quantity} #{plant.name} added to cart."
  end

  def destroy
    id = params[:id]
    session[:shopping_cart].delete(id)
    plant = Plant.find(id)

    flash[:notice] = "#{plant.name} removed from cart."
    redirect_to cart_index_path
  end

  def index
    cart_items = session[:shopping_cart]
    @cart_products = Plant.where(id: cart_items.keys)
    @cart_items_with_quantity = {}
    @cart_products.each do |product|
      quantity = cart_items[product.id.to_s]
      @cart_items_with_quantity[product] = quantity
    end
  end

  def invoice
    email = params[:email] unless params[:email].empty?
    address = params[:address] unless params[:address].empty?
    tax_rate = params[:province].to_i

    customer = Customer.create(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: email || "Not provided",
      address: address || "Not provided",
      tax_rate_id: tax_rate
    )

    @cart_items_with_quantity = session[:shopping_cart]

    order = customer.orders.new

    @total_price = 0
    @gst_total = 0
    @pst_total = 0
    @hst_total = 0
    @cart_items_with_quantity.each do |product_id, quantity|
      product = Plant.find_by(id: product_id.to_i)
      product_multiply_quantity = product.price * quantity
      product_gst = (customer.tax_rate.gst / 100) * product_multiply_quantity
      product_pst = (customer.tax_rate.pst / 100) * product_multiply_quantity
      product_hst = (customer.tax_rate.hst / 100) * product_multiply_quantity
      @gst_total = @gst_total + product_gst
      @pst_total = @pst_total + product_pst
      @hst_total = @hst_total + product_hst
      @total_price = @total_price + product_multiply_quantity

      product.update(stock: product.stock - quantity)

      order_plant = order.order_plants.build(
        quantity: quantity,
        ordered_price: product.price,
        plant_id: product.id
      )
    end
    @overall_total = @total_price + @gst_total + @pst_total + @hst_total

    order.total = @total_price
    order.gst_tax = @gst_total
    order.pst_tax = @pst_total
    order.hst_tax = @hst_total
    order.total_price = @overall_total
    order.save

    session[:shopping_cart] = {}
    redirect_to cart_index_path
  end
end
