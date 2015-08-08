module ZmRorHack

  # 用于定义可在类继承连上继承的实例变量。区别于了变量，兄弟类之间不会互相影响。
  module ClassLevelInheritableAttributes
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def inheritable_attributes(*args)
        @inheritable_attributes ||= [:inheritable_attributes]
        @inheritable_attributes += args
        args.each do |arg|
          class_eval <<-RUBY
          class << self; attr_accessor :#{arg} end
          RUBY
        end
        @inheritable_attributes
      end

      def inherited(subclass)
        super
        (@inheritable_attributes||[]).each do |inheritable_attribute|
          instance_var = "@#{inheritable_attribute}"
          subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
        end
      end
    end
  end
end

require 'zm_ror_hack/active_record_hack'
require 'zm_ror_hack/array_hack'
require 'zm_ror_hack/hash_hack'
require 'zm_ror_hack/kernel_hack'
require 'zm_ror_hack/module_hack'
require 'zm_ror_hack/nil_hack'
require 'zm_ror_hack/object_hack'
require 'zm_ror_hack/string_hack'
require "zm_ror_hack/version"
