module AutoCompleteJquery      
  unloadable  
  def self.included(base)
    base.extend(ClassMethods)
  end

  #
  # Example:
  #
  #   # Controller
  #   class BlogController < ApplicationController
  #     auto_complete_for :post, :title
  #   end
  #
  #   # View
  #   <%= text_field_with_auto_complete :post, title %>
  #
  # By default, auto_complete_for limits the results to 10 entries,
  # and sorts by the given field.
  # 
  # auto_complete_for takes a third parameter, an options hash to
  # the find method used to search for the records:
  #
  #   auto_complete_for :post, :title, :limit => 15, :order => 'created_at DESC'
  #
  # For help on defining text input fields with autocompletion, 
  # see ActionView::Helpers::JavaScriptHelper.
  #
  # For more on jQuery auto-complete, see the docs for the jQuery autocomplete 
  # plugin used in conjunction with this plugin:
  # * http://www.dyve.net/jquery/?autocomplete
  module ClassMethods
    def auto_complete_for(object, method, options = {})
      define_method("auto_complete_for_#{object}_#{method}") do
        object_constant = object.to_s.camelize.constantize
        
        find_options = { 
          :conditions => [ "LOWER(#{method}) LIKE ?", '%' + params[:q].downcase + '%' ], 
          :order => "#{method} ASC",
          :select => "#{object_constant.table_name}.#{method}",
          :limit => 10 }.merge!(options)
        
        @items = object_constant.find(:all, find_options).collect(&method)

        render :text => @items.join("\n")
      end
    end
    
    def multiple_auto_complete_for(object, methods, options = {})
      define_method("auto_complete_for_#{object}_#{methods.join('_')}") do
        object_constant = object.to_s.camelize.constantize
        conditions = methods.collect { |method| "translate(LOWER(#{method}), '\303\241\303\251\303\255\303\263\303\272\303\274\303\261', 'aeiouun') LIKE :q" }.join(' OR ')
        condition_values = { :q => '%' + params[:q].downcase + '%'}
        
        # Filtering options (conditions)
        if params[:options]
          extra_conditions = " AND " + params[:options].keys.collect {|k| "#{k} = :#{k}"}.join(' AND ') 
          params[:options].each {|key,val| condition_values[key.to_sym] = val}
        end
        
        # Select options (display values)
        select = methods.collect { |method| "#{object_constant.table_name}.#{method}" };
        extra_select = if params[:select]
                          params[:select].split.collect { |attribute| attribute = attribute.split('.')[0] ; "#{object_constant.table_name}.#{attribute.foreign_key}"}
                       else
                          []
                       end
        
        find_options = { 
          :conditions => [ "(#{conditions}) #{extra_conditions}", condition_values ],
          :order => methods.collect { |method| "#{method} ASC" }.join(', '),
          :select => (["#{object_constant.table_name}.id"] + select + extra_select).join(', '),
          :limit => 10 }.merge!(options)
        
        @items = object_constant.find(:all, find_options).collect do |record|
                  # We get the methods string appended
                  row = methods.collect { |method| record.send(method) if method != 'id' }.compact.join(' ') + '|' + record.id.to_s
                  # Now we get the extra select options for extra display values
                  if params[:select]
                    row += '|' + params[:select].split.collect { |method| method.split('.').inject(record) { |obj, method| obj.nil? ? next : obj.send(method)} }.join('|')
                  end
                  row
                 end
        render :text => @items.join("\n")
      end
    end
    
  end
  
end
