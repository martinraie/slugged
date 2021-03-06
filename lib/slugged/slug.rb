module Slugged
  class Slug < ActiveRecord::Base
    self.table_name = "slugs"
  
    validates_presence_of :record_id, :slug, :scope
  
    scope :ordered,    order('created_at DESC')
    scope :only_slug,  select(:slug)
    scope :for_record, lambda { |r| where(:record_id => r.id, :scope => Slugged.key_for_scope(r)) }
    scope :for_slug,   lambda { |scope, slug| where(:scope=> scope.to_s, :slug => slug.to_s)}
  
    if methods.include? :pluck
      def self.id_for(scope, slug)
        ordered.for_slug(scope, slug).pluck(:record_id).first
      end
      
      def self.previous_for(record)
        ordered.only_slug.for_record(record).pluck(:slug)
      end
    else
      def self.id_for(scope, slug)
        ordered.for_slug(scope, slug).first.try(:record_id)
      end
    
      def self.previous_for(record)
        ordered.only_slug.for_record(record).all.map(&:slug)
      end
    end
    
    def self.record_slug(record, slug)
      scope = Slugged.key_for_scope(record)
      # Clear slug history in this scope before recording the new slug
      for_slug(scope, slug).delete_all
      new.tap do |history|
        history.scope     = scope
        history.record_id = record.id
        history.slug      = slug.to_s
        history.save
      end
    end
    
    def self.remove_history_for(record)
      for_record(record).delete_all
    end
  
    def self.usable?
      table_exists? rescue false
    end
  
  end
end