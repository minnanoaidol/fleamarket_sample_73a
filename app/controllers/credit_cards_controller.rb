class CreditCardsController < ApplicationController
  require "payjp" 

  def new
  end

  def create 
    
    Payjp.api_key = Rails.application.credentials.dig(:payjp, :PAYJP_SECRET_KEY)

    if params["payjp_token"].blank?
      redirect_to action: "new", alert: "クレジットカードを登録できませんでした。"
    else
      customer = Payjp::Customer.create(
        email: current_user.email,
        card: params["payjp_token"],
        metadata: {user_id: current_user.id} 
      )

      @card = CreditCard.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      @card.save

      redirect_to credit_card_path(current_user.id)
    end

  end

  def show
    @card = CreditCard.find_by(user_id: current_user.id)
    if @card.blank?
      redirect_to action: "new" 
    else
      Payjp.api_key = Rails.application.credentials.dig(:payjp, :PAYJP_SECRET_KEY)

      customer = Payjp::Customer.retrieve(@card.customer_id)

      @customer_card = customer.cards.retrieve(@card.card_id)

      @exp_month = @customer_card.exp_month.to_s

      @exp_year = @customer_card.exp_year.to_s.slice(2,3)
    end
  end

  def destroy
    @card = CreditCard.find_by(user_id: current_user.id)
    if @card.blank?
      redirect_to action: "new" 
    else
      Payjp.api_key = Rails.application.credentials.dig(:payjp, :PAYJP_SECRET_KEY)

      customer = Payjp::Customer.retrieve(@card.customer_id)

      customer.delete

      @card.delete

    end
  end

  def buy
    @product = Product.find(params[:product_id])
    # @images = @product.images.all
    
    if user_signed_in?
      @user = current_user
      if @user.credit_cards.present?
        Payjp.api_key = Rails.application.credentials.dig(:payjp, :PAYJP_SECRET_KEY)
        @card = CreditCard.find_by(user_id: current_user.id)
        customer = Payjp::Customer.retrieve(@card.customer_id)
        @customer_card = customer.cards.retrieve(@card.card_id)
      else
        redirect_to  new_credit_card_path, alert: "クレジット登録してください。"
      end
    end
  end

  def pay
    @product = Product.find(params[:product_id])
    # @images = @product.images.all
      
    @product.with_lock do
      if current_user.credit_cards.present?
        @card = CreditCard.find_by(user_id: current_user.id)
        Payjp.api_key = Rails.application.credentials.dig(:payjp, :PAYJP_SECRET_KEY)
        charge = Payjp::Charge.create(
          amount: @product.price,
          customer: Payjp::Customer.retrieve(@card.customer_id),
          currency: 'jpy'
        )
        
      else
        redirect_to  new_credit_card_path, alert: "クレジット登録してください。"
      end
    end
  end
  
end
