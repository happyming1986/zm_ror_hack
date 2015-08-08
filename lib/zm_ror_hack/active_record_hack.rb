module ZmRorHack

  module ActiveRecordBaseSingletonClassHack

    # 用于模型使用view(视图)时的创建新对象后,获取的对象的id总是null或0的bug,需要建一个字段,这个方法应在放在所有其他before_create和after_create和after_commit的回调前面,并且视图中,应包含hash_column这个字段,实际上hash_column字段是在real_model这个模型的对应表中.
    def use_mysql_view(real_model, *args)
      opts             = args.extract_options!.with_indifferent_access
      self.primary_key = 'id'
      hash_column      = (opts[:hash_column]||'mysql_view_bug_fix_id').to_s
      fails '没有设置hash列。' unless hash_column.in?(real_model.column_names) && hash_column.in?(self.column_names)

      after_initialize do
        self.id = nil if id.is?(0)
      end

      before_create do
        begin
          self[hash_column] = SecureRandom.hex
        end while real_model.exists?(hash_column => self[hash_column])
      end

      after_create do
        id      = real_model.find_by(hash_column => self[hash_column]).id
        self.id = id
      end
    end

    def in_and_ref(table)
      includes(table).references(table.to_s.pluralize)
    end

    [:save, :create, :update].each do |type|
      define_method "assign_on_#{type}" do |column, value, options = {}|
        options = options.with_indifferent_access
        send "before_#{type}" do
          block = lambda do
            tmp_value = if value.is_a? Proc
                          instance_eval(&value)
                        else
                          value
                        end
            send("#{column}=", tmp_value)
          end
          if options.key?(:if)
            if options[:if].is_a? Proc
              block.call if instance_eval(&options[:if])
            else
              block.call if options[:if]
            end
            next
          end
          if options.key?(:unless)
            if options[:unless].is_a? Proc
              block.call unless instance_eval(&options[:unless])
            else
              block.call unless options[:if]
            end
            next
          end
          block.call
        end
      end
    end

    # 序列化属性.
    def serialize_hack(attr_name, class_name = Object, options = {})
      serialize(attr_name, class_name)

      if class_name == Array && options.with_indifferent_access['delete_blank_string']
        before_save do
          new_array = send(attr_name)
          new_array.delete_if do |item|
            item.is_a?(String) && item.blank?
          end
          send(attr_name.to_s + '=', new_array)
        end
      end
    end

    def ming(str, _options = {})
      human_attribute_name(str, options = {})
    end
  end
end

class ActiveRecord::Base
  extend ZmRorHack::ActiveRecordBaseSingletonClassHack
  include ZmRorHack::ClassLevelInheritableAttributes
end