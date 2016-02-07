class OwnershipsController < ApplicationController
  before_action :logged_in_user

  def create
    if params[:asin]
      @item = Item.find_or_initialize_by(asin: params[:asin])
    else
      @item = Item.find(params[:item_id])
    end

    # itemsテーブルに存在しない場合はAmazonのデータを登録する。
    if @item.new_record?
      begin
        # TODO 商品情報の取得 Amazon::Ecs.item_lookupを用いてください
        response = Amazon::Ecs.item_lookup(params[:asin] ,
                                            response_group: 'Medium' ,
                                            country: 'jp')
      rescue Amazon::RequestError => e
        return render :js => "alert('#{e.message}')"
      end

      amazon_item       = response.items.first
      @item.title        = amazon_item.get('ItemAttributes/Title')
      @item.small_image  = amazon_item.get("SmallImage/URL")
      @item.medium_image = amazon_item.get("MediumImage/URL")
      @item.large_image  = amazon_item.get("LargeImage/URL")
      @item.detail_page_url = amazon_item.get("DetailPageURL")
      @item.raw_info        = amazon_item.get_hash
      @item.save!
    end

    # TODO ユーザにwant or haveを設定する
    # params[:type]の値ににHaveボタンが押された時には「Have」,
    # Wantボタンがされた時には「Want」が設定されています。
    if params[:type] == "Have"
      # Haveボタン
      #@item = Item.find(params[:item_id])
      @item = Item.find(@item)
      current_user.have(@item)
    else
      # Wantボタン
      #@item = Item.find(params[:item_id])
      @item = Item.find(@item)
      current_user.want(@item)
    end
  end

  def destroy
    @item = Item.find(params[:item_id])

    # TODO 紐付けの解除。 
    # params[:type]の値ににHavedボタンが押された時には「Have」,
    # Wantedボタンがされた時には「Want」が設定されています。
    if params[:type] == "Have"
      # Havedボタン
      #@item = current_user.haves.find(params[:id]).item
      
      #ownership = current_user.haves.find(@item)
      #@item = ownership.item
      
      current_user.unhave(@item).item
    else
      # Wantedボタン
      #@item = current_user.wants.find(params[:id]).item
      
      #ownership = current_user.wants.find(@item)
      #@item = ownership.item
      
      current_user.unwant(@item).item
    end
  end
end
