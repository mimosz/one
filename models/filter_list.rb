# -*- encoding: utf-8 -*-

class FilterList
  include Mongoid::Document
  include Mongoid::Timestamps

  # Referenced
  belongs_to :user, foreign_key: 'seller_nick'

  # Fields
  field :price_min,       type: Integer, default: 0
  field :price_max,       type: Integer, default: 0

  field :rate_min,        type: Integer, default: 0
  field :rate_max,        type: Integer, default: 0

  field :parents_count,  type: Integer, default: 0

  field :child_ids,        type: Array,   default: []
  field :outer_ids,        type: Array,   default: []
  field :item_ids,         type: Array,   default: []
  field :unknown_ids,      type: Array,   default: []
  
  field :seller_nick,      type: String
  field :name,             type: String

  # Scopes
  default_scope asc(:price_min, :rate_min, :name) # 默认排序

  # Callbacks
  before_save :check_item
  before_create :parents_count_cache

  protected

  def parents_count_cache(ids=nil, count=1)
    ids ||=  child_ids
    unless ids.empty?
      FilterList.where(seller_nick: seller_nick).also_in(_id: ids).each do |child|
        child.inc(:parents_count, count)
      end
    end
  end
  
  def check_item # 检查商品编码
    unless outer_ids.empty?
      uncheck_ids = outer_ids.to_a
      checked_ids = []
      num_iids = []
      unknown_ids = []
      Item.where(nick:seller_nick).also_in(outer_id: uncheck_ids).each do |item|
        if uncheck_ids.include?(item.outer_id)
          checked_ids << item.outer_id
          num_iids << item.num_iid
        end
      end    
      self.unknown_ids = (uncheck_ids - checked_ids) # 剩余的未知编码
      self.outer_ids = checked_ids # 商家编码
      self.item_ids = num_iids     # 商品编码
    end
  end
  
end