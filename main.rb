require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MAX = 17
INITIAL_POT_AMOUNT = 500

helpers do
  def calculate_total(cards) #[["Suit", "Value"],["Suit", "Value"],..]
    hand = cards.map{|e| e[1]}
    total = 0

    #card value counter
    hand.each do |v|
      if v == "ace"
        total += 11
      elsif v.to_i == 0
        total += 10
      else
        total += v.to_i
      end
    end

    #correction for aces
    hand.select{|e| e == "ace"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end 

    total
  end

  def card_image(card) #["Suit", "value"]
    suit = card[0]
    value = card[1]

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='img-rounded'>"
  end

  def dealer_total
    calculate_total(session[:dealers_cards])
  end

  def player_total
    calculate_total(session[:players_cards])
  end

  def winner!(msg)
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @play_again = true
    @success = "<strong>#{session[:player_name]} wins. #{msg}</strong>"
    @show_hit_and_stay = false
  end

  def loser!(msg)
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @play_again = true
    @error = "<strong>#{session[:player_name]} loses. #{msg}</strong>"
    @show_hit_and_stay = false
  end

  def tie!(msg)
    @play_again = true
    @success = "<strong>#{session[:player_name]} and dealer tie at #{player_total} #{msg}</strong>"
    @show_hit_and_stay = false
  end
end

before do
  @show_hit_and_stay = true
end

get "/" do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/start_game'
  end
end

get "/start_game" do
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :start_game
end

post "/start_game" do
  # if session[:player_name].nil?
  #   @error = "Name is required!"
  #   halt erb(:start_game)
  # end
  session[:player_name] = params[:player_name].capitalize
  redirect '/bet'
end

get "/bet" do
  session[:player_bet] = nil
  erb :bet
end

post "/bet" do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "You need to put in an amount to bet with"
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "You are betting with more money than you have. You only have $#{sessions[:player_pot]}"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect "/game"          
  end

end

get "/game" do
  session[:turn] = session[:player_name]

  #Create Deck
  suit = ['hearts', 'diamonds', 'spades', 'clubs']
  cards = ['2','3','4','5','6','7','8','9','10','jack','queen','king', 'ace']

  session[:deck] = suit.product(cards).shuffle!

  #Create players hand:
  session[:players_cards] = []
  session[:dealers_cards] = []

  #deal cards
  session[:players_cards] << session[:deck].pop
  session[:dealers_cards] << session[:deck].pop
  session[:players_cards] << session[:deck].pop
  session[:dealers_cards] << session[:deck].pop

  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} got Blackjack")
  end

  erb :game
end

post "/game/player/hit" do
  session[:players_cards] << session[:deck].pop
  if player_total > BLACKJACK_AMOUNT
    loser!("You busted at #{player_total}")
  elsif player_total == BLACKJACK_AMOUNT
    redirect "game/dealer"
  end

  erb :game
end

post "/game/player/stay" do
  @success = "You have chosen to stay"
  @show_hit_and_stay = false
  redirect '/game/dealer'
end

get "/game/dealer" do
  session[:turn] = "dealer"
  @show_hit_and_stay = false
  #decision tree
  dealer_total = calculate_total(session[:dealers_cards])
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit Blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}")
  elsif dealer_total >= DEALER_MAX
    # Dealer is 17, 18, 19, 20
    # Dealer stays
    redirect '/game/compare'
  else
    # Dealer hits
    @show_dealer_hit_button = true
  end
  erb :game
end

post "/game/dealer/hit" do
  session[:dealers_cards] << session[:deck].pop
  if dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}")
    @show_dealer_hit_button = false
  end

  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_and_stay = false

  player_total = calculate_total(session[:players_cards])
  dealer_total = calculate_total(session[:dealers_cards])

  if player_total > dealer_total
    winner!("#{session[:player_name]} has #{player_total} and the dealer only has #{dealer_total}")
  elsif dealer_total > player_total
    loser!("Dealer has #{dealer_total} and #{session[:player_name]} only has #{player_total}")
  else
    tie!("")
  end

  erb :game
end

get "/game_over" do
  erb :game_over
end






