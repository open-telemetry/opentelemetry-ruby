class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class if Rails.version >= '7.0.0'
end
