class OrdersController < ApplicationController
require 'will_paginate/array'
  def new
    @order = Order.new
    @friendShips=FriendShip.all
    @friendShipsCreatedByCurrentUser= @friendShips.select{|friendShip|
      friendShip.creator_id == current_user.id

    }
    @friendsAddedTheCurrentUse= @friendShips.select{|friendShip|
      friendShip.myfriend_id == current_user.id

    }

    @friendsCreatedByCurrentUser=@friendShipsCreatedByCurrentUser.collect do |friendShip|

      User.find_by_id!(friendShip.myfriend_id)
    end
    @friendsAddedTheCurrentUser=  @friendsAddedTheCurrentUse.collect do |friendShip|

      User.find_by_id!(friendShip.creator_id)
    end
    @friends = @friendsCreatedByCurrentUser  +  @friendsAddedTheCurrentUser

    @allGroups=Group.all
    @CurrentUserGroups= @allGroups.select{|group|
      group.user_id == current_user.id
    }


    @user_group = []
    @CurrentUserGroups.each do |gg|
      GroupsUser.where(group_id: gg.id).each do |g_u|
        @user_group.append(g_u)
      end
    end

  end

  def index
    @friend_ships = FriendShip.select("myfriend_id").where(creator_id: current_user.id)
    @friend_ships1 = FriendShip.select("creator_id").where(myfriend_id: current_user.id)
    @orders = Order.where(user_id: @friend_ships, user_id: @friend_ships1).last(10).reverse
    @myorders = Order.where(user_id: current_user.id)
  end


def list
    @orders = Order.where(:user => current_user.id).reverse.paginate(page: params[:page], per_page: 2)
    # @userOrders = UserOrder.find_by_sql("select count(distinct user_orders.user_id) from user_orders where user_orders.order_id = 5")
    # @orders.each do |order|
    @userOrders= InvitedFriend.select("distinct invited_friends.user_id").joins("INNER JOIN orders ON invited_friends.order_id = orders.id").count
    # FriendShip.where("creator_id = ? AND myfriend_id =  ?" ,current_user.id , friendId)
    # @userOrders= InvitedFriend.where(order_id: @orders.pluck("id"))

    # order.update(joined: @nOfJoined)
 end


  def show
    @order = Order.find(params[:id])
    @invited_friends = InvitedFriend.where(order_id: params[:id])

    @invited_user = false
    @invited_friends.each do |invited|
      if invited.user_id == current_user.id && invited.acceptStatus == "joined"
        @invited_user = true
        break
      end
    end


    @friends = FriendShip.where(creator_id: @order.user_id)
    @friends1 = FriendShip.where(myfriend_id: @order.user_id)
    flag = false
    if @order.user_id == current_user.id
      flag = true
      @invited_user = true
    end
    @friends.each do |f|
      if f.myfriend_id == current_user.id
        flag = true
        break
      end
    end

    @friends1.each do |f|
      if f.creator_id == current_user.id
        flag = true
        break
      end
    end

    if !flag
      redirect_to orders_path
    end
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
    redirect_to orders_list_path
  end

def create
    @order = Order.new(order_params)
    myfriends_ids = params["myfriends_ids"].split(",").map { |s| s.to_i }
    @order.invited = myfriends_ids.length
    @order.save


    myfriends_ids.each do |myfriend_id|
      @notification = Notification.create(:body => current_user.name + " invited you to this order",
                                          :reciever_id => myfriend_id, :order_id => @order.id,
                                          :not_type => 1, :status => 1, :sender_id => current_user.id)
      @invited_friends = InvitedFriend.create(:user_id => myfriend_id, :order_id => @order.id,
                                          :acceptStatus => "waiting")
    end

    redirect_to orders_list_path
  end

  def friends_data
    @friend_ships = FriendShip.select("myfriend_id").where(creator_id: current_user.id)
    @friend_ships1 = FriendShip.select("creator_id").where(myfriend_id: current_user.id)
    @orders = Order.where(user_id: @friend_ships, user_id: @friend_ships1).last(10).reverse
    render :json => @orders, :include => :user
  end

  def update
    @order=Order.find(params[:id])
    @order.update(status: 'finished')
    redirect_to orders_list_path
  end


private
  def order_params
    params.require(:order).permit(:meal, :restaurant, :menuImg, :status, :invited ).merge(:user_id => current_user.id )
  end

end
