# encoding: utf-8
# frozen_string_literal: true

module AssociateJsonb
  module Persistence
    private
      def _update_row(attribute_names, attempted_action = "update")
        self.class._update_record(
          attributes_with_info(attribute_names),
          @primary_key => id_in_database
        )
      end
  end
end
