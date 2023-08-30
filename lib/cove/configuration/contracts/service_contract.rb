require "dry-validation"

module Cove
  module Configuration
    module Contracts
      class ServiceContract < Dry::Validation::Contract
        params do
          required(:service_name).filled(:string)
          required(:image).filled(:string)
          required(:roles).value(:array, min_size?: 1).each do
            hash do
              required(:name).filled(:string)
              optional(:container_count).filled(:integer)
              optional(:ingress).value(:array).each do
                hash do
                  required(:type).value(included_in?: ["port", "port_range"])
                  required(:source).value(:filled?)
                  required(:target).filled(:integer)
                end
              end
            end
          end
        end

        role_names = []

        rule(:roles).each do |index:|
          if index == 0
            role_names.clear
          end
          key([:roles, index, :name]).failure("#{value[:name]} is not a valid name. The name for each role must be unique.") if role_names.include?(value[:name])
          role_names << value[:name]
          if value[:ingress].present?
            value[:ingress].each_with_index do |ingress, ingress_index|
              source_key = key([:roles, index, :ingress, ingress_index, :source])
              if ingress[:type].eql?("port")
                source_key.failure("must be an integer") unless ingress[:source].is_a?(::Integer)
              elsif ingress[:type].eql?("port_range")
                source_key.failure("must be an array of integers") unless ingress[:source].is_a?(::Array)
                if ingress[:source].is_a?(::Array)
                  source_key.failure("size of source array must be greater than or equal to the container count") if value[:container_count].present? && ingress[:source].size < value[:container_count]
                  ingress[:source].each_with_index do |source, source_index|
                    source_key.failure("the element at index #{source_index} in the array must be an integer") unless source.is_a?(::Integer)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
